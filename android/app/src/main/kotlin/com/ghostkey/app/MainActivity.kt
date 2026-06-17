package com.ghostkey.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by the local_auth plugin (BiometricPrompt
// runs as a Fragment, which FlutterActivity does not host).
class MainActivity: FlutterFragmentActivity()
