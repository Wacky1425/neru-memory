import 'package:flutter/material.dart';
String formatMemoryDate(DateTime? d)=>d==null?'未設定':'${d.year}/${d.month}/${d.day}';
String formatMemoryDateTime(DateTime? d)=>d==null?'未設定':'${d.year}/${d.month}/${d.day} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
Future<DateTime?> pickMemoryDate(BuildContext c,DateTime? current)async{final now=DateTime.now();return showDatePicker(context:c,initialDate:current??now,firstDate:DateTime(now.year-1),lastDate:DateTime(now.year+30));}
Future<DateTime?> pickMemoryDateTime(BuildContext c,DateTime? current)async{final d=await pickMemoryDate(c,current);if(d==null||!c.mounted)return current;final t=await showTimePicker(context:c,initialTime:current==null?TimeOfDay.now():TimeOfDay.fromDateTime(current));if(t==null)return DateTime(d.year,d.month,d.day);return DateTime(d.year,d.month,d.day,t.hour,t.minute);}
