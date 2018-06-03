---

layout: default
title: RxSwift中UIControl的 bind

---
RxSwift中UIControl 使用bind 绑定到controlEvent中出现的异常并分析原因
<!-- more -->


## RxSwift中UIControl的 bind

### bind操作符

以绑定到ObserverType为例，bind操作符创建一个新的订阅，并把订阅收到的元素发送给observer，可以简单理解为转发。绑定到ObserverType方法及其注释：

```

    /**
    Creates new subscription and sends elements to observer.
    
    In this form it's equivalent to `subscribe` method, but it communicates intent better, and enables
    writing more consistent binding code.
    
    - parameter to: Observer that receives events.
    - returns: Disposable object that can be used to unsubscribe the observer.
    */
    public func bind<O: ObserverType>(to observer: O) -> Disposable where O.E == E {
        return self.subscribe(observer)
    }
```

### bind的问题

在开始使用RXSwift时，可能会遇到的问题是A 绑定 B，而A发生complete、error时，B信号也会随着结束，当A结束之后，无法继续使用B发送信号了。

```
    let bag = DisposeBag.init()

	let a = PublishSubject<String>.init()
	let b = PublishSubject<String>.init()
	let c = PublishSubject<String>.init()
	
	a.bind(to: b).disposed(by: bag)
	
	test.subscribe(onNext: { (text) in
         print("text")
	}, onError: { (error) in
		  print("error")
	}, onCompleted: {
         print("complete")
	}) {
		  print("dispose")
	}.disposed(by: bag)
	
	
	a.onNext("1")
	a.onComplete()
	
	b.onNext("2")
	
	
```

上述代码输出为：

```
	1
```

接下来是一个比较隐晦的问题：绑定UI控件交互事件时，无法UI交互事件会随着页面释放（当UI控件生命周期与父视图相同）而结束。

问题代码：

```
class ViewController: UIViewController {
    let bag = DisposeBag.init()
    let sendText = PublishSubject<String>.init()

	// 按钮点击时 push 到TestViewController
    @IBAction func send() {
        let vc = TestViewController.init()
        // 将 vc 中 button 的点击事件绑定到 sendText
        vc.button.rx.tap.bind(to: sendText).disposed(by: bag)
        navigationController?.pushViewController(vc, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        sendText.subscribe(onNext: { (text) in
            print(text)
        }, onError: { (error) in
            print("error")
        }, onCompleted: {
            print("completed")
        }) {
            print("disposed")
            }.disposed(by: bag)

    }
}

class TestViewController: UIViewController {
    let button = UIButton.init(type: .custom)
}


```

在ViewController页面触发 `send()` 方法时，进入 `TestViewController` 页面，点击 `button` 时，收到next事件，控制台输出 "tap"，当退出`TestViewController`页面时，`button` 释放，此时会发送`onCompleted`， `onDispose` 事件，也会被`sendText`的订阅收到，`sendText` 事件也就结束了，显然这不是义务场景上正常的做法。


<p align="center">
<img src="/assets/images/RxControlEvent_dispose.png" width ="500">
</p>
<p align="center">
Debug 堆栈1
</p>

<p align="center">
<img src="/assets/images/RxControlEvent_complete.png" width ="500">
</p>
<p align="center">
Debug 堆栈2
</p>




从debug堆栈信息可以看到，由于`TestViewController`的释放，导致`button`释放，触发了`button`绑定的点击事件的dispose。这一点可以从 `vc.button.rx.tap` 中 `tap` 方法的实现来看：

```
// 来源于RXCocoa UIButton+Rx.swift

extension Reactive where Base: UIButton {
    
    /// Reactive wrapper for `TouchUpInside` control event.
    public var tap: ControlEvent<Void> {
        return controlEvent(.touchUpInside)
    }
}

```

关于 `controlEvent(.touchUpInside)` 的实现源码：

```
	// 来源于RXCocoa UIControl+Rx.swift


    /// Reactive wrapper for target action pattern.
    ///
    /// - parameter controlEvents: Filter for observed event types.
    public func controlEvent(_ controlEvents: UIControlEvents) -> ControlEvent<()> {
        let source: Observable<Void> = Observable.create { [weak control = self.base] observer in
                MainScheduler.ensureExecutingOnScheduler()

                guard let control = control else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                let controlTarget = ControlTarget(control: control, controlEvents: controlEvents) {
                    control in
                    observer.on(.next(()))
                }

                return Disposables.create(with: controlTarget.dispose)
            }
            .takeUntil(deallocated)

        return ControlEvent(events: source)
    }

```

上述代码中倒数第二行`.takeUntil(deallocated)`，调用者是`Observable.create`创建出来的`Observable `变量。这个就是导致事件结束的原因。

我们先看 `takeUntil`操作符：

<b>[takeUntil 操作符将镜像源 Observable，它同时观测第二个 Observable。一旦第二个 Observable 发出一个元素或者产生一个终止事件，那个镜像的 Observable 将立即终止。](https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/takeUntil.html)</b>

也就是说，当deallocated这个Observable发出next或者complete时，导致`controlEvent(.touchUpInside) ` 创建的`ControlEvent`发出next或者complete。

为了完整说明，我们看下`deallocated`这个Observable是什么：

```
    
// 来源于 RxCocoa NSObject+Rx.swift
    
extension Reactive where Base: AnyObject {
    
    /**
    Observable sequence of object deallocated events.
    
    After object is deallocated one `()` element will be produced and sequence will immediately complete.
    
    - returns: Observable sequence of object deallocated events.
    */
    public var deallocated: Observable<Void> {
        return synchronized {
            if let deallocObservable = objc_getAssociatedObject(base, &deallocatedSubjectContext) as? DeallocObservable {
                return deallocObservable._subject
            }

            let deallocObservable = DeallocObservable()

            objc_setAssociatedObject(base, &deallocatedSubjectContext, deallocObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return deallocObservable._subject
        }
    }
}

```

这里其实看方法注释就能明白：

Observable sequence of object deallocated events.
After object is deallocated one `()` element will be produced and sequence will immediately complete.

当对象dealloc的时候，发出complete事件的Observable。至此也就能完整解释`button`释放时发出dispose和complete事件的问题了。

简单解释一下源码实现，这个变量返回的是base已经绑定的`deallocatedSubjectContext`对应的值，当这个值为空时绑定一个新创建的`DeallocObservable`。

关于base变量：

```
public struct Reactive<Base> {
    /// Base object to extend.
    public let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    public init(_ base: Base) {
        self.base = base
    }
}

```

也就是`button.rx.tap`中的`button`对象，也就是给`button`绑定了`deallocatedSubjectContext`对应的`DeallocObservable`。关于`DeallocObservable`：

```
fileprivate final class DeallocObservable {
    let _subject = ReplaySubject<Void>.create(bufferSize:1)

    init() {
    }

    deinit {
        _subject.on(.next(()))
        _subject.on(.completed)
    }
}

```

当`DeallocObservable`释放时，发送next和complete事件。

至此完整解释是：`button`释放时，已经绑定的`DeallocObservable._subject`也随之释放，`_subject`释放时，发送next和complete，而`_subject`的next和complete也通过takeUntil作用到`button`的点击的controlEvent上，controlEvent也就有next和complete。因此`button`释放时有dispose和complete事件。
