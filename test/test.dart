import '../lib/xml.dart';

main() {
  String content = """
<fragment id="af">
  <image src="assets/tail.png" href="/image" />
  <text href="/text">Some Text > HEre </text>
  <text href="/text/muti/line">
    Muti
    Line 
  </text>
  <text href="/text/muti/line">
    single line
  </text>
  <text>
  </text>
  <view height="100" width="200" href="/home"></view>
  <view height="100">
    <view>
      <text>Some Text</text>
      <text>Some Text</text>
    </view>
  </view>
</fragment>
  """;

  List<Fragment> fragments = parse(content);
  String dist = serialize(fragments, compcat: false);
  print(dist);
}
