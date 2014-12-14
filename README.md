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

## Progress

The progress callback is passed as the third parameter of `then` method, which named `onProgress`. The progress value is propagated by default and can be stopped by returning a negative value.

```swift
promise.then(
    onFulfilled: nil,
    onRejected: nil,
    onProgress: { (progress) -> Float in
        return progress // The return value is used to propagate if it is locate in range 0.0...1.0
})
```

Or use the shortcut method `progress`:

```swift
promise.progress { (progress) -> Void in
    // The return value can also be omitted
}
```

If there are other promises in a then chain publish their progress, the value of the consequential progress can be balanced with a value called 'fraction'. The 'fraction' value indicates how much weight the promise returned in `onFulfilled` takes.

```swift
promise.then(
    onFulfilled: { () -> Promise<Void> in
        let (anotherDeferred, anotherPromise) = Promise<Void>.defer()
        return anotherPromise
    },
    onProgress: { (progress) -> Float in
        return progress * 0.5   // The '0.5' indicates `promise` and `anotherPromise` take same weight
})
```

The aggregate functions also notify progress in proper ways

| Method | Progress meaning |
| :--:  | :-- |
| `all` | Average of all sub promises' progress |
| `race` | Max of all sub promises' progress |

## Licence

[MIT](https://github.com/coppercash/IPromise/blob/master/LICENSE)
