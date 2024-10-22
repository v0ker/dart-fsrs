import 'dart:core';
import 'dart:math';
import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// TODO: document
enum State {
  /// TODO: document
  newState(0),

  /// TODO: document
  learning(1),

  /// TODO: document
  review(2),

  /// TODO: document
  relearning(3);

  const State(this.val);

  final int val;
}

/// TODO: document
enum Rating {
  /// TODO: document
  again(1),

  /// TODO: document
  hard(2),

  /// TODO: document
  good(3),

  /// TODO: document
  easy(4);

  const Rating(this.val);

  final int val;
}

/// TODO: document
class ReviewLog {
  ReviewLog(
    this.rating,
    this.scheduledDays,
    this.elapsedDays,
    this.review,
    this.state,
  );

  /// TODO: document
  Rating rating;

  /// TODO: document
  int scheduledDays;

  /// TODO: document
  int elapsedDays;

  /// TODO: document
  DateTime review;

  /// TODO: document
  State state;

  @override
  String toString() {
    return jsonEncode({
      "rating": rating.toString(),
      "scheduledDays": scheduledDays,
      "elapsedDays": elapsedDays,
      "review": review.toString(),
      "state": state.toString(),
    });
  }
}

/// Store card data
@unfreezed
class Card with _$Card {
  const Card._();

  factory Card.def(
    DateTime due,
    DateTime lastReview, [
    @Default(0) double stability,
    @Default(0) double difficulty,
    @Default(0) int elapsedDays,
    @Default(0) int scheduledDays,
    @Default(0) int reps,
    @Default(0) int lapses,
    @Default(State.newState) State state,
  ]) = _Card;

  factory Card.fromJson(Map<String, Object?> json) => _$CardFromJson(json);

  /// Construct current time for due and last review
  factory Card() {
    return _Card(DateTime.now().toUtc(), DateTime.now().toUtc());
  }

  double? getRetrievability(DateTime now) {
    const decay = -0.5;
    final factor = pow(0.9, 1 / decay) - 1;

    if (state == State.review) {
      final elapsedDays =
          (now.difference(lastReview).inDays).clamp(0, double.infinity).toInt();
      return pow(1 + factor * elapsedDays / stability, decay).toDouble();
    } else {
      return null;
    }
  }
}

/// TODO: document
/// Store card and review log info
class SchedulingInfo {
  late Card card;
  late ReviewLog reviewLog;

  SchedulingInfo(this.card, this.reviewLog);
}

/// TODO: document
/// Calculate next review
class SchedulingCards {
  late Card again;
  late Card hard;
  late Card good;
  late Card easy;

  SchedulingCards(Card card) {
    again = card.copyWith();
    hard = card.copyWith();
    good = card.copyWith();
    easy = card.copyWith();
  }

  /// TODO: document
  void updateState(State state) {
    switch (state) {
      case State.newState:
        again.state = State.learning;
        hard.state = State.learning;
        good.state = State.learning;
        easy.state = State.review;
      case State.learning:
      case State.relearning:
        again.state = state;
        hard.state = state;
        good.state = State.review;
        easy.state = State.review;
      case State.review:
        again.state = State.relearning;
        hard.state = State.review;
        good.state = State.review;
        easy.state = State.review;
        again.lapses++;
    }
  }

  /// TODO: document
  void schedule(
    DateTime now,
    int hardInterval,
    int goodInterval,
    int easyInterval,
  ) {
    again.scheduledDays = 0;
    hard.scheduledDays = hardInterval;
    good.scheduledDays = goodInterval;
    easy.scheduledDays = easyInterval;
    again.due = now.add(Duration(minutes: 5));
    hard.due = hardInterval > 0
        ? now.add(Duration(days: hardInterval))
        : now.add(Duration(minutes: 10));
    good.due = now.add(Duration(days: goodInterval));
    easy.due = now.add(Duration(days: easyInterval));
  }

  /// TODO: document
  Map<Rating, SchedulingInfo> recordLog(Card card, DateTime now) => {
        Rating.again: SchedulingInfo(
          again,
          ReviewLog(
            Rating.again,
            again.scheduledDays,
            card.elapsedDays,
            now,
            card.state,
          ),
        ),
        Rating.hard: SchedulingInfo(
          hard,
          ReviewLog(
            Rating.hard,
            hard.scheduledDays,
            card.elapsedDays,
            now,
            card.state,
          ),
        ),
        Rating.good: SchedulingInfo(
          good,
          ReviewLog(
            Rating.good,
            good.scheduledDays,
            card.elapsedDays,
            now,
            card.state,
          ),
        ),
        Rating.easy: SchedulingInfo(
          easy,
          ReviewLog(
            Rating.easy,
            easy.scheduledDays,
            card.elapsedDays,
            now,
            card.state,
          ),
        ),
      };
}

/// TODO: document
class Parameters {
  Parameters({
    double? requestRetention,
    int? maximumInterval,
    List<double>? weight,
  })  : requestRetention = requestRetention ?? 0.9,
        maximumInterval = maximumInterval ?? 36500,
        weight = weight ??
            const [
              0.4072,
              1.1829,
              3.1262,
              15.4722,
              7.2102,
              0.5316,
              1.0651,
              0.0234,
              1.616,
              0.1544,
              1.0824,
              1.9813,
              0.0953,
              0.2975,
              2.2042,
              0.2407,
              2.9466,
              0.5034,
              0.6567,
            ];

  /// TODO: document
  double requestRetention;

  /// TODO: document
  int maximumInterval;

  /// TODO: document
  List<double> weight;
}
