#!/bin/bash
# اضغط مرتين على الملف ده في macOS، أو اسحب ملف النسخة عليه.
# بيطلب الملف → يثبّت التبعيات → يعمل معاينة → يطلب تأكيد → يستعيد.
# مفيش أي كتابة في Firestore غير بعد ما تكتب RESTORE بخط إيدك.

set -e
cd "$(dirname "$0")"

PROJECT_ID="${HESBA_PROJECT:-hesba-business}"

say() { printf '\n%s\n' "$1"; }
bye() { printf '\n'; read -r -p "اضغط Enter للإغلاق..."; exit "${1:-0}"; }

say "══════════════════════════════════════════"
say "  استعادة نسخة احتياطية لتطبيق حسبة"
say "══════════════════════════════════════════"

# ١) الملف: إما مسحوب على الأيقونة ($1) أو نافذة اختيار.
FILE="${1:-}"
if [ -z "$FILE" ]; then
  FILE=$(osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  activate
  set chosenFile to choose file with prompt "اختر ملف النسخة الاحتياطية لتطبيق حسبة"
  return POSIX path of chosenFile
end tell
APPLESCRIPT
)
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  say "❌ ما اخترتش ملف صحيح."
  bye 1
fi

case "$FILE" in
  *.json|*.json.gz) ;;
  *) say "❌ الامتداد لازم يكون .json أو .json.gz"; bye 1 ;;
esac

say "📦 الملف: $FILE"

# ٢) Node + تبعيات السكربت.
if ! command -v node >/dev/null 2>&1; then
  say "❌ Node غير مثبّت. ثبّته من https://nodejs.org ثم أعد المحاولة."
  bye 1
fi

if [ ! -d node_modules/firebase-admin ]; then
  say "⏳ أول تشغيل: بثبّت تبعيات الاستعادة..."
  npm install || { say "❌ فشل تثبيت التبعيات. شغّل: npm install"; bye 1; }
fi

# ٣) بيانات الدخول (بدون ما نطبع المفتاح أو نعرضه).
HAS_CREDS=0
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  HAS_CREDS=1
fi
if [ -f serviceAccount.json ]; then HAS_CREDS=1; fi
if [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then HAS_CREDS=1; fi

if [ "$HAS_CREDS" -eq 0 ]; then
  say "⚠️ محتاج مفتاح حساب الخدمة مرة واحدة:"
  say "   Firebase Console ← Project settings ← Service accounts"
  say "   ← Generate new private key ← احفظ الملف باسم:"
  say "   $(pwd)/serviceAccount.json"
  say "▶ هفتح لك صفحة Service accounts في المتصفح..."
  open "https://console.firebase.google.com/project/$PROJECT_ID/settings/serviceaccounts/adminsdk" || true
  printf '\n'
  read -r -p "بعد ما تحط الملف، اضغط Enter (أو Ctrl+C للإلغاء)... "
  if [ ! -f serviceAccount.json ]; then
    say "❌ الملف لسه مش موجود في المجلد ده."
    bye 1
  fi
fi
say "✅ بيانات الدخول جاهزة"

# ٤) معاينة بدون أي كتابة.
say "🔍 معاينة (dry-run) — مفيش أي تعديل لحد دلوقتي..."
node restore.js "$FILE" --project="$PROJECT_ID" --dry-run || {
  say "❌ المعاينة فشلت. البيانات ما اتغيرتش."
  bye 1
}

# ٥) تأكيد صريح قبل الكتابة.
printf '\n'
read -r -p "راجع الأعداد فوق. اكتب RESTORE للتأكيد: " ANSWER
if [ "$ANSWER" != "RESTORE" ]; then
  say "تم الإلغاء — مفيش أي حاجة اتكتبت."
  bye 0
fi

# ٦) تنفيذ الاستعادة.
say "⏳ جارٍ الاستعادة..."
node restore.js "$FILE" --project="$PROJECT_ID" --yes || {
  say "❌ الاستعادة فشلت. راجع الرسالة فوق."
  bye 1
}

say "✅ خلصت! افتح التطبيق وتأكد إن البيانات رجعت."
bye 0
