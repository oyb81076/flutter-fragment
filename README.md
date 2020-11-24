# flutter-fragment

## 片段源码

fragments/top.xml

```xml
<view width=20 height=30></view>
```

fragments/button.xml

```xml
<fragment id="bottom">
  <view width=20 height=30>
  </view>
<fragment>
```

fragments/left.xml

```xml
<fragment id="left">
  <view width=20 height=30>
  </view>
<fragment>
```

## 片段

## Usage In App

```dart
// 使用的时候
class App extends StatelessWidget{
  build(){
    return FragmentProvider(
      asset: 'assets/fragment.xml',
      remote: 'http://192.168.1.1/fragment.xml',
      child: Container(
        child: [
          Fragment(id: 'top'),
          Container(
            child: Fragment(id: 'bottom'),
          )
          Fragment(id: 'bottom'),
        ]
      )
    )
  }
}
```
