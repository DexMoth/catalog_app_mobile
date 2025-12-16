import '../models/item.dart';

Item? movingItem;

void startMoving(Item item) {
  movingItem = item;
}

void stopMoving() {
  movingItem = null;
}

bool get isMoving => movingItem != null;