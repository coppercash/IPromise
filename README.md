<a href="http://promises-aplus.github.com/promises-spec"><img src="https://promises-aplus.github.com/promises-spec/assets/logo-small.png" alt="Promises/A+ logo" align="right"></a>

# IPromise

Promise library in Swift conforming to [Promises/A+](http://promises-aplus.github.com/promises-spec), and more.

## Type safe

The type of the value you get in `then` closure is guaranteed to be the same one with the type of `Promise`. No downcast is needed. 

```swift
let promise: Promise<Int> = answerToEverthing();

promise
    .then { (value: Int) -> Bool in
        return value == 42
    }
    .then { (value: Bool) -> Promise<String> in
        return value ?
            Promise(value: "I knew it!") :
            Promise(reason: NSError())
    }
    .then { (value: String) -> Void in
        println(value.stringByAppendingString(" Oh yeah!"))
}
```

## Type free

Promise with no type constraint is also supported as `APlusPromise`. Just like in **Javascript**, you are free to pass value of any type.

```swift
let typeFreePromise: APlusPromise = answerToUniverse()

typeFreePromise.then(
    onFulfilled: { (value: Any?) -> Any? in
        let isItStill42 = (value as Int) == 42
        return nil;
    },
    onRejected: { (reason: Any?) -> Any? in
        return nil;
    }
)
```

And the 2 kinds of promises are bridgeable.

```swift
let fromTypeFree: Promise<Any?> = Promise(vagueThenable: typeFreePromise)
let fromTypeSafe: APlusPromise = APlusPromise(promise: fromTypeFree)
```

## Aggregate

You can combine several promises as a new promise.

```swift
let promises: [Promise<Int>] = [
    promiseA,
    promiseB,
    promiseC,
]

let promise = arrayOrVariadic ?
    Promise<[Int]>.all(promises) :
    Promise<[Int]>.all(promiseA, promiseB, promiseC);

promise.then { (value) -> Void in
    for number: Int in value {
        println(number)
    }
}
```

Following aggregate methods are supported for now

| Method | Fulfill condition | Reject condition | Promise | APlusPromise |
| :--:  | :-- | :-- | :--: | :--: |
| `all` | When every item in the array fulfils | If (and when) any item rejects | √ | √ |
| `race` | As soon as any item fulfills | As soon as any item rejects | √ | √ |

## Chain

Broad return value types and number of closures of method `then` are supported.

```swift
Promise { (resolve, reject) -> Void in
   resolve(value: "Something complex")
   }
   .then(
       onFulfilled: { (value: String) -> Void in
           return
       },
       onRejected: { (reason: NSError) -> Void in
           return
   })
   .then(
       onFulfilled: { (value: Void) -> Int in
           return 1
       },
       onRejected: { (reason: NSError) -> Int in
           return 0
   })
   .then { (value) -> Promise<String> in
           let error = NSError(domain: "BadError", code: 1000, userInfo: nil)
           return Promise<String>(reason: error)   
   }
   .catch { (reason) -> Void in
       println(reason)
}
```

## Thenable support

**Thenable** is supported via protocal.

```swift
class ThenableObject: Thenable {
    
    typealias ValueType = NSData
    typealias ReasonType = NSError
    typealias ReturnType = Void
    typealias NextType = Void
    
    func then(
        #onFulfilled: Optional<(value: NSData) -> Void>,
        onRejected: Optional<(reason: NSError) -> Void>,
        onProgress: Optional<(progress: Float) -> Float>
        ) -> Void {
        // Implement
    }
}

let thenableObject = ThenableObject()
let promise = Promise(thenable: thenableObject)
```

## Deferred
Promise should be regarded as a wrapper for a future value. But to "resolve" or "reject" the value is not really its work. Under this situation, `Deferred` object is on call. It is useful when to offer a `Promise` to other part of the program.

```swift
func someAwsomeData() -> Promise<NSString> {
    let deferred = Deferred<NSString>()
    
    NSURLConnection.sendAsynchronousRequest(
        NSURLRequest(URL: NSURL(string: "http://so.me/awsome/api")!),
        queue: NSOperationQueue.mainQueue())
        { (response, data, error) -> Void in
            if error == nil {
                deferred.resolve(NSString(data: data, encoding: NSUTF8StringEncoding)!)
            }
            else {
                deferred.reject(error)
            }
    }
    
    return deferred.promise
}
```
There is a short hand for getting `Deferred`:

```swift
let (deferred, promise) = Promise<String>.defer()
```

## Licence

[MIT](https://github.com/coppercash/IPromise/blob/master/LICENSE)
