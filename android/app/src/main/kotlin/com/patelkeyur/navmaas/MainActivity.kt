package com.patelkeyur.navmaas

import com.ryanheise.audioservice.AudioServiceFragmentActivity

// Background audio (audio_service) needs its activity; the fragment variant
// is what Health Connect (M4b) needs too.
class MainActivity : AudioServiceFragmentActivity()
