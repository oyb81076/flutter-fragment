# flutter-fragment

```xml
<fragment id="top">
  <view width=20 height=30>
  </view>
<fragment>
<fragment id="bottom">
  <view width=20 height=30>
  </view>
<fragment>
<fragment id="left">
  <view width=20 height=30>
  </view>
<fragment>
```

```dart
// 打开项目的时候
Fragment.load('assets/fragment.html', remote: 'http://oss.www.baidu.com/assets.html');

// 使用的时候
class AppHome extends StatelessWidget{
  build(){
    return Container(
      child: [
        Fragment(id: 'top'),
        Container(
          child: Fragment(id: 'bottom'),
        )
        Fragment(id: 'bottom'),
      ]
    )
  }
}
```
