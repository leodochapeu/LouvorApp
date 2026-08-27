import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:louvor_app/core/data/supabase_table_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('isTransientRealtimeError is true for timedOut and channelError', () {
    expect(
      isTransientRealtimeError(
        const RealtimeSubscribeException(RealtimeSubscribeStatus.timedOut),
      ),
      isTrue,
    );
    expect(
      isTransientRealtimeError(
        const RealtimeSubscribeException(RealtimeSubscribeStatus.channelError),
      ),
      isTrue,
    );
  });

  test('isTransientRealtimeError is false for other failures', () {
    expect(
      isTransientRealtimeError(
        const RealtimeSubscribeException(RealtimeSubscribeStatus.closed),
      ),
      isFalse,
    );
    expect(isTransientRealtimeError(Exception('network')), isFalse);
  });

  test('watchSupabaseTable emits REST data before live updates', () async {
    final live = StreamController<List<int>>();
    addTearDown(live.close);

    final events = <Object>[];
    final sub = watchSupabaseTable<int>(
      fetchAll: () async => [1, 2],
      watchLive: () => live.stream,
    ).listen(events.add, onError: events.add);
    addTearDown(sub.cancel);

    await Future<void>.delayed(Duration.zero);
    expect(events, [
      [1, 2],
    ]);

    live.add([1, 2, 3]);
    await Future<void>.delayed(Duration.zero);
    expect(events, [
      [1, 2],
      [1, 2, 3],
    ]);
  });

  test('watchSupabaseTable swallows realtime timeouts after REST snapshot', () async {
    final live = StreamController<List<int>>();
    addTearDown(live.close);

    final events = <Object>[];
    final sub = watchSupabaseTable<int>(
      fetchAll: () async => [1],
      watchLive: () => live.stream,
    ).listen(events.add, onError: events.add);
    addTearDown(sub.cancel);

    await Future<void>.delayed(Duration.zero);

    live.addError(
      const RealtimeSubscribeException(RealtimeSubscribeStatus.timedOut),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, [
      [1],
    ]);

    live.add([1, 2]);
    await Future<void>.delayed(Duration.zero);
    expect(events, [
      [1],
      [1, 2],
    ]);
  });

  test('watchSupabaseTable still reports REST failures', () async {
    final live = StreamController<List<int>>();
    addTearDown(live.close);

    final events = <Object>[];
    final sub = watchSupabaseTable<int>(
      fetchAll: () async => throw Exception('rest down'),
      watchLive: () => live.stream,
    ).listen(events.add, onError: events.add);
    addTearDown(sub.cancel);

    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    expect(events.single, isA<Exception>());
  });
}
