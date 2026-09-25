import 'package:flutter/material.dart';
import '../home/home_page.dart'; import '../lists/lists_page.dart'; import '../goals/goals_page.dart'; import '../calendar/calendar_page.dart'; import '../settings/settings_page.dart'; import '../capture/quick_capture.dart';

class AppShell extends StatefulWidget { const AppShell({super.key}); @override State<AppShell> createState()=>_AppShellState(); }
class _AppShellState extends State<AppShell>{
  int index=0;
  final pages=const [HomePage(),ListsPage(),GoalsPage(),CalendarPage(),SettingsPage()];
  @override Widget build(BuildContext context){
    final wide=MediaQuery.sizeOf(context).width>=900;
    if(wide){return Scaffold(body:Row(children:[NavigationRail(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),labelType:NavigationRailLabelType.all,leading:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:FloatingActionButton.small(onPressed:()=>showQuickCapture(context),child:const Icon(Icons.add))),destinations:const [NavigationRailDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:Text('ホーム')),NavigationRailDestination(icon:Icon(Icons.checklist_outlined),selectedIcon:Icon(Icons.checklist),label:Text('リスト')),NavigationRailDestination(icon:Icon(Icons.flag_outlined),selectedIcon:Icon(Icons.flag),label:Text('目標')),NavigationRailDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:Text('カレンダー')),NavigationRailDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:Text('設定'))]),const VerticalDivider(width:1),Expanded(child:pages[index]) ]));}
    return Scaffold(body:pages[index],floatingActionButton:index==4?null:FloatingActionButton(onPressed:()=>showQuickCapture(context),child:const Icon(Icons.add)),floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'ホーム'),NavigationDestination(icon:Icon(Icons.checklist_outlined),selectedIcon:Icon(Icons.checklist),label:'リスト'),NavigationDestination(icon:Icon(Icons.flag_outlined),selectedIcon:Icon(Icons.flag),label:'目標'),NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'予定'),NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'設定')]));
  }
}
