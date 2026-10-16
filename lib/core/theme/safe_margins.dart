// المسافات الآمنة المصممة للوضع الغامر — بديلة لمساحات النظام
// Designed safe margins for immersive fullscreen — replacing system insets
//
// في الشاشة الكاملة (immersiveSticky) يخفي النظام شريطي الحالة والتنقل،
// لكنه ما زال يبلّغ Flutter عن مساحتهما (inset) — ولو اعتمدناها لظهر
// فراغ علوي قبيح. لذا نتجاهل الـ inset تماماً ونستخدم قيماً تصميمية
// ثابتة وموحدة في كل الشاشات.
// In immersive fullscreen the system hides the bars but still reports
// their inset — relying on it leaves an ugly top gap. So we ignore the
// inset entirely and use fixed, unified design values on every screen.

/// مسافة آمنة علوية: تتجاوز منطقة كاميرا السيلفي + تنفس جمالي
/// Top safe margin: clears the selfie-camera area + aesthetic breathing room
const double kSafeMarginTop = 32.0;

/// مسافة آمنة سفلية: فوق منطقة إيماءات التنقل + تنفس جمالي
/// Bottom safe margin: above the gesture-navigation zone + aesthetic room
const double kSafeMarginBottom = 24.0;
