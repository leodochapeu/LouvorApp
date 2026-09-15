import 'package:supabase_flutter/supabase_flutter.dart';

/// Websocket subscribe failures that Supabase puts on `.stream()` while the
/// socket is still connecting or reconnecting. Data usually arrives right
/// after; treating them as fatal makes the UI flash an error screen.
bool isTransientRealtimeError(Object? error) {
  if (error is! RealtimeSubscribeException) return false;
  return error.status == RealtimeSubscribeStatus.timedOut ||
      error.status == RealtimeSubscribeStatus.channelError;
}

/// Live table feed that is safe to bind to the UI:
///
/// 1. Emits a REST snapshot first, so the first frame is data or a real
///    fetch error — never a websocket timeout.
/// 2. Then forwards Supabase Realtime updates, swallowing the subscribe
///    timeouts the client emits while the socket catches up.
Stream<List<T>> watchSupabaseTable<T>({
  required Future<List<T>> Function() fetchAll,
  required Stream<List<T>> Function() watchLive,
}) async* {
  yield await fetchAll();
  yield* watchLive().handleError(
    (Object _, StackTrace _) {},
    test: (error) => isTransientRealtimeError(error),
  );
}
