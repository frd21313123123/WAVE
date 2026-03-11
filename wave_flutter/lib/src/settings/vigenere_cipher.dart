const String _enLower = 'abcdefghijklmnopqrstuvwxyz';
const String _enUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _ruLower =
    '\u0430\u0431\u0432\u0433\u0434\u0435\u0451\u0436\u0437\u0438\u0439'
    '\u043a\u043b\u043c\u043d\u043e\u043f\u0440\u0441\u0442\u0443\u0444'
    '\u0445\u0446\u0447\u0448\u0449\u044a\u044b\u044c\u044d\u044e\u044f';
const String _ruUpper =
    '\u0410\u0411\u0412\u0413\u0414\u0415\u0401\u0416\u0417\u0418\u0419'
    '\u041a\u041b\u041c\u041d\u041e\u041F\u0420\u0421\u0422\u0423\u0424'
    '\u0425\u0426\u0427\u0428\u0429\u042A\u042B\u042C\u042D\u042E\u042F';

String normalizeVigenereKey(String? value, {String fallback = 'WAVE'}) {
  final key = (value ?? '').trim();
  return key.isEmpty ? fallback : key;
}

({List<int> en, List<int> ru}) buildVigenereShifts(
  String? key, {
  String fallback = 'WAVE',
}) {
  final shiftsEn = <int>[];
  final shiftsRu = <int>[];
  for (final char in normalizeVigenereKey(key, fallback: fallback).split('')) {
    final lower = char.toLowerCase();
    final enIndex = _enLower.indexOf(lower);
    if (enIndex >= 0) {
      shiftsEn.add(enIndex);
      continue;
    }

    final ruIndex = _ruLower.indexOf(lower);
    if (ruIndex >= 0) {
      shiftsRu.add(ruIndex);
    }
  }

  return (en: shiftsEn, ru: shiftsRu);
}

String transformWithVigenere(
  String? text,
  String? key, {
  bool decrypt = false,
  String fallbackKey = 'WAVE',
}) {
  final shifts = buildVigenereShifts(key, fallback: fallbackKey);
  if (shifts.en.isEmpty && shifts.ru.isEmpty) {
    return text ?? '';
  }

  final direction = decrypt ? -1 : 1;
  var enCounter = 0;
  var ruCounter = 0;
  final source = text ?? '';
  final buffer = StringBuffer();

  for (final char in source.split('')) {
    final enLowerIndex = _enLower.indexOf(char);
    if (enLowerIndex >= 0) {
      if (shifts.en.isEmpty) {
        buffer.write(char);
      } else {
        final shift = shifts.en[enCounter % shifts.en.length];
        final nextIndex =
            (enLowerIndex + direction * shift + _enLower.length) %
                _enLower.length;
        buffer.write(_enLower[nextIndex]);
        enCounter += 1;
      }
      continue;
    }

    final enUpperIndex = _enUpper.indexOf(char);
    if (enUpperIndex >= 0) {
      if (shifts.en.isEmpty) {
        buffer.write(char);
      } else {
        final shift = shifts.en[enCounter % shifts.en.length];
        final nextIndex =
            (enUpperIndex + direction * shift + _enUpper.length) %
                _enUpper.length;
        buffer.write(_enUpper[nextIndex]);
        enCounter += 1;
      }
      continue;
    }

    final ruLowerIndex = _ruLower.indexOf(char);
    if (ruLowerIndex >= 0) {
      if (shifts.ru.isEmpty) {
        buffer.write(char);
      } else {
        final shift = shifts.ru[ruCounter % shifts.ru.length];
        final nextIndex =
            (ruLowerIndex + direction * shift + _ruLower.length) %
                _ruLower.length;
        buffer.write(_ruLower[nextIndex]);
        ruCounter += 1;
      }
      continue;
    }

    final ruUpperIndex = _ruUpper.indexOf(char);
    if (ruUpperIndex >= 0) {
      if (shifts.ru.isEmpty) {
        buffer.write(char);
      } else {
        final shift = shifts.ru[ruCounter % shifts.ru.length];
        final nextIndex =
            (ruUpperIndex + direction * shift + _ruUpper.length) %
                _ruUpper.length;
        buffer.write(_ruUpper[nextIndex]);
        ruCounter += 1;
      }
      continue;
    }

    buffer.write(char);
  }

  return buffer.toString();
}

String vigenereEncrypt(
  String? text,
  String? key, {
  String fallbackKey = 'WAVE',
}) {
  return transformWithVigenere(
    text,
    key,
    decrypt: false,
    fallbackKey: fallbackKey,
  );
}

String vigenereDecrypt(
  String? text,
  String? key, {
  String fallbackKey = 'WAVE',
}) {
  return transformWithVigenere(
    text,
    key,
    decrypt: true,
    fallbackKey: fallbackKey,
  );
}
