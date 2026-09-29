Neru Memory v1.10 Release Candidate
上書きOK / 削除なし
ベース: v1.9

V1完成仕上げ:
- タグ入力の空白区切り正規表現を修正
- HomeでGoogle連携FutureとGoogle予定の二重表示を解消
- 検索結果からTask / Want / Futureを直接編集可能
- 検索0件表示を追加
- Goalにタグ表示
- Goal削除導線を追加
- Milestoneをタップして編集 / 削除 / 進捗 / 重み変更
- Milestoneの重み付き進捗からGoal進捗を自動再計算
- Want / Future / Goal削除時にREMEMBER内部状態も掃除
- 表示バージョン v1.10 RC

V1の主要機能:
Home TODAY/NEXT/OVERDUE/GOALS/REMEMBER
Task / Want / Future / Goal / Milestone / Inbox
Google Calendar連携・リンク同期・重複抑止
通知 / Android TODAY Widget / Quick Capture Widget
全体検索 / タグ
Trash 30日 / JSONバックアップ
Firestore同期
Light / Dark / System

適用:
v1.9の上から上書き
flutter run

最終確認:
1 起動・Googleログイン
2 Quick Capture→Inbox→4分類
3 Task期限・通知・完了
4 Want保存・タグ検索
5 Future→Google→相互編集→片方/両方削除
6 Goal→Milestone編集→Goal進捗自動更新
7 REMEMBER あとで/30日保留
8 Trash復元/完全削除
9 Android Widget 2種
10 再起動後データ維持

この環境にはFlutter SDKがないため flutter analyze/build は未実行。
