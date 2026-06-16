/// Shared audio session limits for playback and recording.
const int kSampleRate = 44100;
const int kChannels = 2;
const int kMaxSessionSeconds = 60;
const int kMaxSessionSamples = kSampleRate * kChannels * kMaxSessionSeconds;

/// PCM blocks rendered per feed-isolate iteration.
const int kFeedFrames = 512;

/// Samples to buffer before starting SoLoud playback (~93 ms stereo).
const int kPrefillSamples = kFeedFrames * kChannels * 4;

/// Duration of one feed buffer at [kSampleRate] (informational).
const Duration kFeedBufferDuration = Duration(
  microseconds: kFeedFrames * 1000000 ~/ kSampleRate,
);

const Duration kMaxSessionDuration = Duration(seconds: kMaxSessionSeconds);
