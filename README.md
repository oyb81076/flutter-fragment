# flutter-fragment

## 片段源码

fragments/top.xml

```xml
<view width=20 height=30></view>
```

templates/bottom.xml

```xml
<view width=20 height=30>
  <text>bottom</text>
</view>
```

fragments/main.xml

```xml
<view width=20 height=30>
  <fragment url="http://192.168.0.1">
    <view>
      <text>Loading....</text>
    </view>
  </fragment>
</view>
```

## 片段打包

```dart
main() async {
  Fragments fragments = await parseDir('/path/to/templates/root');
  String dist = serialize(fragments);
  await File('/path/to/assets/templates-bundle.xml').writeAsString(dist);
}
```

## Usage In App

```dart
// 使用的时候
class App extends StatelessWidget {
  build(){
    return FragmentProvider(
      asset: 'assets/templates-bundle.xml',
      local: 'templates.xml',
      remote: 'http://192.168.1.1/templates.xml',
      child: Container(
        child: [
          Fragment(id: 'top'),
          Container(
            child: Fragment(id: 'bottom'),
          ),
          Fragment(id: 'bottom'),
          Fragment(url: 'http://192.168.1.1/some-dynamic-xml-render-by-server', children: [
            Text('Loading...'),
          ]),
        ],
      );
    );
  }
}
```
