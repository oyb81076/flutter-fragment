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

## template 打包方案 xml vs protobuf vs json

1. protobuf 修改后升级方便, 新旧版本客户端可以实现相对平滑的过度
2. protobuf 打包后体积小
3. xml 可读性好, 导报上传到 oss 的文件可以直接下载调试
4. xml 服务端动态生成 xml 方便, 利于开发
5. xml 有版本兼容问题, 新旧版本支持的标签及属性可能有所不同
6. xml 服务端动态生成 xml 的时候服务端写错了, 客户端容易崩溃
7. json 兼容性不好, 但是反序列化方便

## Usage In App

```dart
// 使用的时候
class App extends StatelessWidget {
  build(){
    return FragmentProvider(
      // app打包时资源存放的目录
      asset: 'assets/templates-bundle.xml',
      // 缓存地址
      cacheDir: '__cache__',
      // 远程模版下载
      remote: 'http://192.168.1.1/templates.xml',
      // 当模版引擎解析出错的时候会将错误信息post到这个地址
      logger: 'http://192.168.1.1/api/template-parse-error',
      // 远程模版直接覆盖本地模版, 而不是合并
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
