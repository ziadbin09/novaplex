package com.manzar.manzar

import android.content.Context
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

/// Tells the Cast SDK to use Google's Default Media Receiver, which can
/// play standard media (mp4, etc.) without registering a custom receiver app.
class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        return CastOptions.Builder()
            .setReceiverApplicationId(
                CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
            )
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? =
        null
}
