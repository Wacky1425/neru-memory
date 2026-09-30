import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../lists/lists_page.dart';
import '../goals/goals_page.dart';
import '../calendar/calendar_page.dart';
import '../settings/settings_page.dart';
import '../capture/quick_capture.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState()=>_AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index=0;
  final pages=const [HomePage(),ListsPage(),GoalsPage(),CalendarPage(),SettingsPage()];
  static const destinations=<NavigationRailDestination>[
    NavigationRailDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:Text('ホーム')),
    NavigationRailDestination(icon:Icon(Icons.checklist),label:Text('リスト')),
    NavigationRailDestination(icon:Icon(Icons.flag_outlined),label:Text('目標')),
    NavigationRailDestination(icon:Icon(Icons.calendar_month_outlined),label:Text('予定')),
    NavigationRailDestination(icon:Icon(Icons.settings_outlined),label:Text('設定')),
  ];
  @override Widget build(BuildContext context)=>PopScope(
    canPop:false,
    onPopInvokedWithResult:(didPop,result){if(!didPop&&index!=0)setState(()=>index=0);},
    child:LayoutBuilder(builder:(context,c){
      final desktop=c.maxWidth>=900;
      final content=IndexedStack(index:index,children:pages);
      if(desktop){
        return Scaffold(
          body:Row(children:[
            NavigationRail(
              selectedIndex:index,
              onDestinationSelected:(v)=>setState(()=>index=v),
              extended:c.maxWidth>=1200,
              leading:Padding(padding:const EdgeInsets.symmetric(vertical:16),child:FilledButton.icon(
                onPressed:()=>showQuickCapture(context),icon:const Icon(Icons.add),label:const Text('追加'))),
              destinations:destinations,
            ),
            const VerticalDivider(width:1),
            Expanded(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1100),child:content))),
          ]),
        );
      }
      return Scaffold(
        body:content,
        floatingActionButton:index==4?null:FloatingActionButton.small(onPressed:()=>showQuickCapture(context),child:const Icon(Icons.add)),
        floatingActionButtonLocation:FloatingActionButtonLocation.endFloat,
        bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'ホーム'),
          NavigationDestination(icon:Icon(Icons.checklist),label:'リスト'),
          NavigationDestination(icon:Icon(Icons.flag_outlined),label:'目標'),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'予定'),
          NavigationDestination(icon:Icon(Icons.settings_outlined),label:'設定'),
        ]),
      );
    }),
  );
}
