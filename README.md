# CoWBox
CoWBox is a high-efficiency property wrapper library for the Swift programming language. Leveraging the Copy-on-Write (CoW) semantics, this library optimizes state management and enhances performance. CoWBox efficiently wraps properties of classes, structures, or any type, delaying memory copies until the uniqueness of a reference is lost, thereby minimizing resource utilization.

# Usage
To use CoWBox, simply wrap your property with @CoWBox. For example:

```swift
struct MyStruct {
    @CoWBox var myProperty: SomeType
}
```
## ObservedCoWBox
```Swift
@Observable
final class MyClass {
    @ObservationIgnored
    @ObservedCoWBox var myProperty: SomeType
}
```
This endows myProperty with Copy-on-Write semantics.
