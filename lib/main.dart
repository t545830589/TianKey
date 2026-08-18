import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const TianKeyApp()); }

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Tian Key V11',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF02060D),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF1595FF), secondary: Color(0xFFFF8A1C)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF03070D), elevation: 0),
    ),
    home: const TianKeyHome(),
  );
}

enum AccessMode { admin, borrower }
enum PageTab { vehicle, bluetooth, borrow, admin, settings }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});
  @override State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const defaultName = '陕A0P92Y';
  static const defaultPassword = '13092991951';
  static const phoneId = 'PHONE-TIANKY-01';
  static const lockGpio = 12, unlockGpio = 13, trunkGpio = 14;

  SharedPreferences? prefs;
  final pwd = TextEditingController();
  final newPwd = TextEditingController();
  final nameCtrl = TextEditingController();
  final hoursCtrl = TextEditingController(text: '2');

  PageTab tab = PageTab.vehicle;
  AccessMode? mode;
  bool ready=false, scanning=false, found=false, connecting=false, connected=false;
  bool timeSynced=false, timeFail=false, autoConnect=true, sound=true, authorized=true, locked=true;
  bool adminSession=false;
  String deviceName=defaultName, deviceId='TIANKEY-AXELA-01', adminPassword=defaultPassword;
  String? adminDevice, borrowCode;
  DateTime? borrowStart, borrowEnd, espTime;
  String status='系统待机：车辆功能锁定，请先进行蓝牙扫描';
  String lastCommand='';
  final logs=<String>[];

  bool get borrowValid => borrowCode!=null && borrowStart!=null && borrowEnd!=null && DateTime.now().isAfter(borrowStart!) && DateTime.now().isBefore(borrowEnd!);
  bool get adminEnabled => connected && mode==AccessMode.admin && adminSession;
  bool get vehicleEnabled => connected && authorized && ((mode==AccessMode.admin && adminSession) || (mode==AccessMode.borrower && borrowValid));

  @override void initState(){super.initState(); load();}
  @override void dispose(){pwd.dispose();newPwd.dispose();nameCtrl.dispose();hoursCtrl.dispose();super.dispose();}

  Future<void> load() async {
    prefs=await SharedPreferences.getInstance();
    final p=prefs!;
    deviceName=p.getString('device_name')??defaultName;
    deviceId=p.getString('device_id')??deviceId;
    adminPassword=p.getString('admin_password')??defaultPassword;
    adminDevice=p.getString('admin_device_id');
    borrowCode=p.getString('borrow_code');
    final s=p.getInt('borrow_start'), e=p.getInt('borrow_end');
    borrowStart=s==null?null:DateTime.fromMillisecondsSinceEpoch(s);
    borrowEnd=e==null?null:DateTime.fromMillisecondsSinceEpoch(e);
    autoConnect=p.getBool('auto_connect')??true;
    sound=p.getBool('sound')??true;
    authorized=p.getBool('authorized')??true;
    ready=true; addLog('APP启动');
    if(borrowEnd!=null && DateTime.now().isAfter(borrowEnd!)) await clearBorrow();
    if(autoConnect && authorized && adminDevice==phoneId) unawaited(autoReconnect());
    if(mounted)setState((){});
  }

  void addLog(String s){logs.add('${DateTime.now()} $s');while(logs.length>200)logs.removeAt(0);}
  void showMsg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}

  Future<void> scan() async {
    if(!ready||scanning||connecting)return;
    setState((){scanning=true;found=false;status='正在扫描 BLE 设备...';}); addLog('BLE扫描');
    await Future.delayed(const Duration(milliseconds:700)); if(!mounted)return;
    setState((){scanning=false;found=true;status='发现车辆：$deviceName';}); addLog('发现 $deviceName');
  }

  Future<void> autoReconnect() async {
    await Future.delayed(const Duration(milliseconds:500));
    if(!mounted||connected||!autoConnect||adminDevice!=phoneId)return;
    setState((){found=true;connecting=true;status='发现已授权设备，正在自动认证...';}); addLog('自动连接开始');
    await Future.delayed(const Duration(milliseconds:600)); if(!mounted)return;
    setState((){connected=true;connecting=false;mode=AccessMode.admin;adminSession=true;timeSynced=false;status='自动认证成功，正在自动同步时间';});
    await syncTime();
  }

  Future<void> connect() async {
    if(!found||connecting||connected)return;
    if(autoConnect&&authorized&&adminDevice==phoneId){await autoReconnect();return;}
    final m=await showDialog<AccessMode>(context:context,barrierDismissible:false,builder:(_)=>dialog('选择连接身份',Column(mainAxisSize:MainAxisSize.min,children:[
      button('管理员连接',Icons.admin_panel_settings,const Color(0xFF1595FF),()=>Navigator.pop(context,AccessMode.admin)),
      const SizedBox(height:10),button('临时借车连接',Icons.key,const Color(0xFFFF8A1C),()=>Navigator.pop(context,AccessMode.borrower)),
    ])));
    if(m==null||!mounted)return;
    pwd.clear();
    final ok=await verify(m); if(!ok||!mounted)return;
    setState((){connecting=true;status='认证成功，正在建立正式 BLE 连接...';}); addLog(m==AccessMode.admin?'管理员认证成功':'临时借车认证成功');
    await Future.delayed(const Duration(milliseconds:600)); if(!mounted)return;
    if(m==AccessMode.admin){adminDevice=phoneId;adminSession=true;await prefs?.setString('admin_device_id',phoneId);}
    setState((){connected=true;mode=m;connecting=false;timeSynced=false;status='BLE连接成功，正在自动同步时间...';}); addLog('ESP32 BLE正式连接');
    await syncTime();
  }

  Future<bool> verify(AccessMode m) async {
    final r=await showDialog<bool>(context:context,barrierDismissible:false,builder:(_)=>dialog(m==AccessMode.admin?'管理员密码':'临时借车密码',Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:pwd,obscureText:true,keyboardType:TextInputType.number,style:const TextStyle(color:Colors.white,fontSize:20),decoration:field('请输入密码')),
      const SizedBox(height:14),
      button('验证并连接',Icons.link,const Color(0xFF1595FF),(){final v=pwd.text.trim();final ok=m==AccessMode.admin?v==adminPassword:borrowValid&&v==borrowCode;if(ok)Navigator.pop(context,true);else{showMsg('密码错误、授权无效或临时密码已过期');addLog('认证失败');}}),
    ])));
    return r??false;
  }

  Future<void> syncTime() async {
    if(!connected)return; await Future.delayed(const Duration(milliseconds:350)); if(!mounted)return;
    if(timeFail){setState((){timeSynced=false;espTime=null;status=mode==AccessMode.admin?'时间同步失败：管理员仍可正常使用':'时间同步失败：无法确认临时授权有效期';});addLog('ESP32 时间同步失败');return;}
    setState((){timeSynced=true;espTime=DateTime.now();status=mode==AccessMode.admin?'已连接 · 时间自动同步成功 · 管理员权限已开放':'已连接 · 时间自动同步成功 · 临时借车权限已开放';});addLog('ESP32 时间同步成功');
  }

  Future<void> disconnect() async {setState((){connected=false;mode=null;adminSession=false;timeSynced=false;espTime=null;status='BLE已断开：车辆功能重新锁定';});addLog('BLE断开，安全保护');showMsg('BLE已断开，车辆功能已锁定');}

  void vehicle(String c){
    if(!vehicleEnabled){showMsg('当前没有车辆控制权限');addLog('拒绝车辆指令 $c');return;}
    late String proto,detail;late int gpio;
    switch(c){case '锁车':proto='suoche';gpio=lockGpio;detail='GPIO12 锁车脉冲';locked=true;break;case '解锁':proto='jiesuo';gpio=unlockGpio;detail='GPIO13 解锁脉冲';locked=false;break;case '寻车':proto='xunche';gpio=lockGpio;detail='GPIO12 连续两次锁车脉冲';break;case '升窗':proto='chuangsheng';gpio=lockGpio;detail='GPIO12 保持7秒';break;case '降窗':proto='chuangjiang';gpio=unlockGpio;detail='GPIO13 保持7秒';break;default:proto='houbeixiang';gpio=trunkGpio;detail='GPIO14 保持7秒';}
    setState((){lastCommand='$proto → GPIO$gpio → $detail';status='$c 已发送：$lastCommand';});addLog('APP 发起 $proto');addLog('ESP32 收到 $proto → GPIO$gpio');showMsg('$c\n$detail');
  }

  Future<void> genBorrow() async {
    if(!adminEnabled)return;final h=(int.tryParse(hoursCtrl.text.trim())??2).clamp(1,24).toInt();final code=(100000+Random().nextInt(900000)).toString();final s=DateTime.now();final e=s.add(Duration(hours:h));
    borrowCode=code;borrowStart=s;borrowEnd=e;await prefs?.setString('borrow_code',code);await prefs?.setInt('borrow_start',s.millisecondsSinceEpoch);await prefs?.setInt('borrow_end',e.millisecondsSinceEpoch);addLog('生成临时借车密码并保存到ESP32');setState((){status='临时借车密码已生成';});showMsg('临时密码：$code\n有效期：$h 小时');
  }
  Future<void> clearBorrow() async {borrowCode=null;borrowStart=null;borrowEnd=null;await prefs?.remove('borrow_code');await prefs?.remove('borrow_start');await prefs?.remove('borrow_end');if(mounted)setState((){});}

  Future<void> changePassword() async {
    if(!adminEnabled)return;newPwd.clear();final ok=await showDialog<bool>(context:context,builder:(_)=>dialog('修改管理员/蓝牙密码',Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:newPwd,obscureText:true,keyboardType:TextInputType.number,style:const TextStyle(color:Colors.white),decoration:field('输入新密码')),const SizedBox(height:12),button('保存到ESP32',Icons.save,const Color(0xFFFF8A1C),()=>Navigator.pop(context,true))])));if(ok!=true)return;
    if(newPwd.text.trim().length<6){showMsg('密码至少6位');return;}adminPassword=newPwd.text.trim();await prefs?.setString('admin_password',adminPassword);addLog('管理员密码修改成功');setState((){});showMsg('新密码已生效，旧密码失效');
  }
  Future<void> changeName() async {
    if(!adminEnabled)return;nameCtrl.text=deviceName;final ok=await showDialog<bool>(context:context,builder:(_)=>dialog('修改设备名称',Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:nameCtrl,style:const TextStyle(color:Colors.white),decoration:field('BLE设备名称')),const SizedBox(height:12),button('保存到ESP32',Icons.save,const Color(0xFF1595FF),()=>Navigator.pop(context,true))])));if(ok!=true)return;
    if(nameCtrl.text.trim().isEmpty)return;deviceName=nameCtrl.text.trim();await prefs?.setString('device_name',deviceName);addLog('设备名称修改成功');setState((){});
  }
  Future<void> toggleAuth() async {if(!adminEnabled)return;authorized=!authorized;await prefs?.setBool('authorized',authorized);addLog(authorized?'恢复设备授权':'关闭设备授权');setState((){status=authorized?'授权已恢复：管理员会话仍有效，车辆功能已开放':'授权已关闭：车辆功能锁定，但管理员会话保留，可再次打开授权';});}
  Future<void> factoryReset() async {
    if(!adminEnabled)return;final ok=await showDialog<bool>(context:context,builder:(_)=>dialog('恢复出厂',Column(mainAxisSize:MainAxisSize.min,children:[const Text('清除管理员密码、管理员设备绑定、授权状态、临时借车授权和相关配置。'),const SizedBox(height:12),button('确认恢复出厂',Icons.delete_forever,const Color(0xFFFF2B1A),()=>Navigator.pop(context,true))])));if(ok!=true)return;
    await prefs?.clear();adminPassword=defaultPassword;adminDevice=null;authorized=true;autoConnect=true;borrowCode=null;borrowStart=null;borrowEnd=null;connected=false;mode=null;adminSession=false;found=false;timeSynced=false;addLog('ESP32 恢复出厂');setState((){status='已恢复未绑定初始状态';});showMsg('恢复出厂完成，管理员初始密码恢复为13092991951');
  }
  Future<void> migrateAdmin() async {if(!adminEnabled)return;adminDevice=phoneId;await prefs?.setString('admin_device_id',phoneId);addLog('管理员席位迁移到当前设备');showMsg('当前手机成为唯一管理员，旧管理员失效');setState((){});}

  InputDecoration field(String s)=>InputDecoration(labelText:s,labelStyle:const TextStyle(color:Colors.white70),enabledBorder:const OutlineInputBorder(borderSide:BorderSide(color:Color(0xFF1595FF))),focusedBorder:const OutlineInputBorder(borderSide:BorderSide(color:Color(0xFFFF8A1C),width:2)));
  Widget dialog(String title,Widget child)=>Dialog(backgroundColor:const Color(0xFF06101D),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:Color(0xFF1595FF))),child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:18),child])));
  Widget button(String text,IconData icon,Color color,VoidCallback tap)=>SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:tap,icon:Icon(icon),label:Text(text),style:FilledButton.styleFrom(backgroundColor:color,foregroundColor:Colors.black,minimumSize:const Size.fromHeight(50))));
  Widget panel(Widget child,{Color border=const Color(0xFF1595FF),EdgeInsets pad=const EdgeInsets.all(14)})=>Container(padding:pad,decoration:BoxDecoration(color:const Color(0xCC020A14),borderRadius:BorderRadius.circular(18),border:Border.all(color:border),boxShadow:[BoxShadow(color:border.withOpacity(.3),blurRadius:14)]),child:child);
  Widget neon(String text,IconData icon,VoidCallback? tap,{bool orange=false}){final c=orange?const Color(0xFFFF8A1C):const Color(0xFF1595FF);final on=tap!=null;return GestureDetector(onTap:tap,child:AnimatedOpacity(opacity:on?1:.35,duration:const Duration(milliseconds:120),child:Container(height:72,decoration:BoxDecoration(color:const Color(0xFF061321),borderRadius:BorderRadius.circular(14),border:Border.all(color:c,width:1.4),boxShadow:[BoxShadow(color:c.withOpacity(.38),blurRadius:12)]),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:c,size:26),const SizedBox(height:5),Text(text,style:TextStyle(color:c,fontWeight:FontWeight.w600))]))));}
  Widget line(String a,String b,{bool active=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(a,style:const TextStyle(color:Colors.white70))),Text(b,style:TextStyle(color:active?const Color(0xFF19D36B):Colors.white,fontWeight:FontWeight.w600))]));

  Widget vehiclePage()=>ListView(padding:const EdgeInsets.all(12),children:[
    panel(ClipRRect(borderRadius:BorderRadius.circular(17),child:Stack(children:[Image.asset('assets/home_car_bg.png',width:double.infinity,height:230,fit:BoxFit.cover),Positioned(left:18,bottom:12,child:Text(deviceName,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold,shadows:[Shadow(color:Colors.black,blurRadius:8)])))])),pad:EdgeInsets.zero),
    const SizedBox(height:12),panel(Column(children:[line('蓝牙',connected?'已连接':'未连接',active:connected),line('登录权限',!connected?'未授权':(mode==AccessMode.admin?'管理员':'临时借车'),active:connected),line('时间',timeSynced?'已同步':'未同步',active:timeSynced),line('授权状态',authorized?'有效':'已关闭',active:authorized),const SizedBox(height:8),Text(status,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70))],),border:const Color(0xFF29394A)),
    const SizedBox(height:12),Row(children:[Expanded(child:neon(scanning?'扫描中...':'蓝牙扫描',Icons.bluetooth_searching,scanning?null:scan,orange:true)),const SizedBox(width:10),Expanded(child:neon(connecting?'连接中...':'连接',Icons.link,found&&!connected&&!connecting?connect:null))]),
    const SizedBox(height:14),panel(Stack(children:[Image.asset('assets/home_controls_bg.png',width:double.infinity,fit:BoxFit.cover,opacity:const AlwaysStoppedAnimation<double>(.72)),Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('车辆控制',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:46),GridView.count(crossAxisCount:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:10,crossAxisSpacing:10,children:[neon('锁车',Icons.lock,vehicleEnabled?()=>vehicle('锁车'):null),neon('解锁',Icons.lock_open,vehicleEnabled?()=>vehicle('解锁'):null),neon('寻车',Icons.directions_car,vehicleEnabled?()=>vehicle('寻车'):null),neon('升窗',Icons.arrow_upward,vehicleEnabled?()=>vehicle('升窗'):null,orange:true),neon('降窗',Icons.arrow_downward,vehicleEnabled?()=>vehicle('降窗'):null,orange:true),neon('后备箱',Icons.inventory_2,vehicleEnabled?()=>vehicle('后备箱'):null,orange:true)])]))])),
    if(lastCommand.isNotEmpty)const SizedBox(height:10),if(lastCommand.isNotEmpty)panel(Text('最近指令：$lastCommand',style:const TextStyle(color:Colors.white70)))
  ]);

  Widget bluetoothPage()=>ListView(padding:const EdgeInsets.all(14),children:[panel(Column(children:[const Text('BLE 连接流程',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),flow('01','扫描',scanning||found||connected),flow('02','发现 $deviceName',found||connected),flow('03','管理员/临时借车认证',mode!=null),flow('04','正式 BLE 连接',connected),flow('05','自动时间同步',timeSynced||timeFail)])),const SizedBox(height:12),Row(children:[Expanded(child:neon('扫描',Icons.bluetooth_searching,scan,orange:true)),const SizedBox(width:10),Expanded(child:neon('断开',Icons.bluetooth_disabled,connected?disconnect:null))]),const SizedBox(height:12),panel(Column(children:[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('模拟时间同步失败'),value:timeFail,onChanged:(v)=>setState(()=>timeFail=v)),if(connected)neon('重新同步时间',Icons.sync,syncTime),const SizedBox(height:10),neon('查看系统日志',Icons.receipt_long,showLogs)]))]);
  Widget flow(String n,String t,bool done)=>ListTile(contentPadding:EdgeInsets.zero,leading:Container(width:36,height:36,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:done?const Color(0xFF1595FF):const Color(0xFF182332),border:Border.all(color:done?const Color(0xFF1595FF):Colors.grey)),child:Text(n)),title:Text(t),trailing:Icon(done?Icons.check_circle:Icons.radio_button_unchecked,color:done?const Color(0xFF19D36B):Colors.grey));

  Widget borrowPage()=>ListView(padding:const EdgeInsets.all(14),children:[panel(ClipRRect(borderRadius:BorderRadius.circular(17),child:Image.asset('assets/borrow_page_bg.png',width:double.infinity,height:190,fit:BoxFit.cover)),pad:EdgeInsets.zero),const SizedBox(height:12),panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('临时借车',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('6位临时密码 + 开始时间 + 结束时间。临时借车只有六项车辆控制，没有管理员控制权。',style:TextStyle(color:Colors.white70)),if(adminEnabled)...[const SizedBox(height:12),TextField(controller:hoursCtrl,keyboardType:TextInputType.number,style:const TextStyle(color:Colors.white),decoration:field('有效小时数 1～24')),const SizedBox(height:10),neon('生成临时借车密码',Icons.key,genBorrow,orange:true)],const SizedBox(height:14),borrowValid?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('当前临时密码',style:TextStyle(color:Colors.white70)),Text(borrowCode!,style:const TextStyle(fontSize:34,letterSpacing:5,fontWeight:FontWeight.bold)),Text('有效至：$borrowEnd'),if(adminEnabled)TextButton(onPressed:clearBorrow,child:const Text('立即作废'))]):const Text('当前没有有效临时借车密码',style:TextStyle(color:Colors.grey))]))]);

  Widget adminPage()=>ListView(padding:const EdgeInsets.all(14),children:[panel(ClipRRect(borderRadius:BorderRadius.circular(17),child:Stack(children:[Image.asset('assets/popup_admin_auth.png',width:double.infinity,height:175,fit:BoxFit.cover),const Positioned(left:18,top:18,child:Text('管理员操作',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold))),Positioned(left:18,bottom:18,child:Text(adminEnabled?'管理员会话已建立':'未进入管理员模式',style:const TextStyle(color:Colors.white70)))])),const SizedBox(height:12),adminRow('修改管理员/蓝牙密码',Icons.password,adminEnabled?changePassword:null),adminRow('修改设备名称',Icons.edit,adminEnabled?changeName:null),adminRow('生成临时借车密码',Icons.key,adminEnabled?genBorrow:null),adminRow(authorized?'授权状态：已开启':'授权状态：已关闭',Icons.verified_user,adminEnabled?toggleAuth:null),adminRow('管理员迁移到当前设备',Icons.swap_horiz,adminEnabled?migrateAdmin:null),adminRow('重新同步时间（诊断）',Icons.sync,adminEnabled&&connected?syncTime:null),adminRow('查看统一系统日志',Icons.receipt_long,showLogs),adminRow('恢复出厂',Icons.delete_forever,adminEnabled?factoryReset:null,red:true),const SizedBox(height:8),panel(const Text('授权切换的正确行为：关闭时车辆功能锁定，但当前管理员会话保留，管理员仍可再次打开授权。',style:TextStyle(color:Colors.white70)),border:const Color(0xFF29394A))]);
  Widget adminRow(String t,IconData i,VoidCallback? tap,{bool red=false}){final c=red?const Color(0xFFFF2B1A):const Color(0xFF19D36B);final on=tap!=null;return Padding(padding:const EdgeInsets.only(bottom:10),child:GestureDetector(onTap:tap,child:AnimatedOpacity(opacity:on?1:.35,duration:const Duration(milliseconds:120),child:panel(Row(children:[Icon(i,color:c,size:28),const SizedBox(width:15),Expanded(child:Text(t,style:const TextStyle(fontSize:17))),const Icon(Icons.chevron_right)]),border:on?c:const Color(0xFF29394A)))));}

  Widget settingsPage()=>ListView(padding:const EdgeInsets.all(14),children:[panel(ClipRRect(borderRadius:BorderRadius.circular(17),child:Image.asset('assets/settings_page_bg.png',width:double.infinity,height:180,fit:BoxFit.cover)),pad:EdgeInsets.zero),const SizedBox(height:12),panel(Column(children:[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('自动连接'),subtitle:const Text('首次认证后，已授权管理员设备无需每天输入密码'),value:autoConnect,onChanged:(v)async{autoConnect=v;await prefs?.setBool('auto_connect',v);setState((){})}),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('声音反馈'),value:sound,onChanged:(v)async{sound=v;await prefs?.setBool('sound',v);setState((){})}),ListTile(contentPadding:EdgeInsets.zero,title:const Text('设备名称'),subtitle:Text(deviceName),trailing:IconButton(onPressed:adminEnabled?changeName:null,icon:const Icon(Icons.edit))),ListTile(contentPadding:EdgeInsets.zero,title:const Text('管理员密码'),subtitle:const Text('已保存，不显示明文'),trailing:IconButton(onPressed:adminEnabled?changePassword:null,icon:const Icon(Icons.edit))),ListTile(contentPadding:EdgeInsets.zero,title:const Text('授权状态'),subtitle:Text(authorized?'有效':'已关闭'),trailing:Switch(value:authorized,onChanged:adminEnabled?(_)=>toggleAuth():null))])),const SizedBox(height:12),panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('设备状态',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),line('设备ID',deviceId),line('管理员席位',adminDevice==null?'未绑定':adminDevice==phoneId?'当前手机':'其他手机'),line('时间',espTime?.toString()??'未同步'),line('车辆',locked?'已锁定':'已解锁'),line('日志','${logs.length}/200')]))]);

  Future<void> showLogs() async {await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF050B14),builder:(_)=>SizedBox(height:MediaQuery.of(context).size.height*.75,child:Column(children:[const SizedBox(height:15),const Text('Tian Key 系统日志',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const Text('APP + ESP32统一日志 · ≤200条 · ≤7天',style:TextStyle(color:Colors.grey)),const Divider(),Expanded(child:logs.isEmpty?const Center(child:Text('暂无日志')):ListView.builder(itemCount:logs.length,itemBuilder:(_,i)=>ListTile(dense:true,title:Text(logs[logs.length-1-i]))))])));}

  @override Widget build(BuildContext context){
    if(!ready)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[vehiclePage(),bluetoothPage(),borrowPage(),adminPage(),settingsPage()];
    return Scaffold(appBar:AppBar(title:const Text('Tian Key V11',style:TextStyle(fontSize:28,fontWeight:FontWeight.w400)),actions:[Icon(connected?Icons.bluetooth:Icons.bluetooth_disabled,color:connected?const Color(0xFF19D36B):Colors.grey,size:28),const SizedBox(width:18)]),body:SafeArea(child:pages[PageTab.values.indexOf(tab)]),bottomNavigationBar:NavigationBarTheme(data:NavigationBarThemeData(backgroundColor:const Color(0xFF14170F),indicatorColor:const Color(0xFF19D36B),labelTextStyle:MaterialStateProperty.all(const TextStyle(fontWeight:FontWeight.w600))),child:NavigationBar(selectedIndex:PageTab.values.indexOf(tab),onDestinationSelected:(i)=>setState(()=>tab=PageTab.values[i]),destinations:const[NavigationDestination(icon:Icon(Icons.directions_car),label:'车辆'),NavigationDestination(icon:Icon(Icons.bluetooth),label:'蓝牙'),NavigationDestination(icon:Icon(Icons.vpn_key),label:'借车'),NavigationDestination(icon:Icon(Icons.admin_panel_settings),label:'管理'),NavigationDestination(icon:Icon(Icons.settings),label:'设置')])));
  }
}
