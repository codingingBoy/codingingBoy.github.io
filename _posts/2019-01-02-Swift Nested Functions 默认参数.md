---

layout: default
title: Swift Nested Functions 默认参数

---
Swift Nested Functions 设置默认参数导致的一个问题
<!-- more -->


## Swift Nested Functions 默认参数

Swift 中给方法设置默认参数时，默认参数必须是一个常量：Type 里 static let 定义的常量，或者Type 外部的let，枚举类型等。当设置其他变量的时候，就会编译错误并提示。当Nested Function 中定义默认参数，可能默认参数是之前定义的一个局部变量，这是编译不会显示这么写有什么问题，但会编译报错：


```
    private func testFunction(_ text: String) {
        let a = "hehe"
        
        func hehe(_ text: String = a) -> String {
            return text
        }
        
        hehe()
    }
```

编译error信息如下：

```
error: Abort trap: 6
```

从编译错误中也没有显示与上述传参有关的问题，但注释上述默认参数后，问题就不复存在。对这一问题的原因，只能推测Nested Function 对默认参数的检查存在纰漏，导致将问题带到后续编译中，以至于出现上述错误信息。