# Wave Messenger Flutter

Flutter-клиент для `Wave Messenger` теперь состоит из двух веток:

- Android: нативный mobile UI на Flutter.
- Windows: desktop shell на Flutter, который открывает ту же веб-версию, что и браузер.

## Что это значит для Windows

Windows-приложение не дублирует веб-функционал отдельным Flutter UI. Вместо этого оно использует `Microsoft Edge WebView2` и загружает тот же web client, что и обычный браузер. За счет этого desktop-версия повторяет браузерную по функционалу.

По умолчанию shell открывает URL, заданный через `WAVE_BASE_URL`. Если `dart-define` не передан, используется текущее значение по умолчанию из Flutter-конфига проекта.

Внутри Windows-приложения можно:

- открыть тот же URL, что и в браузере;
- сменить URL через настройки shell;
- сохранить этот URL локально;
- очистить cookies и cache встроенного WebView;
- использовать `back`, `forward` и `reload`.

## Запуск

```bash
flutter pub get
flutter run
```

Для Windows:

```bash
flutter run -d windows
```

Чтобы запустить shell сразу против нужной веб-версии:

```bash
flutter run -d windows --dart-define=WAVE_BASE_URL=http://127.0.0.1:3000
```

или:

```bash
flutter run -d windows --dart-define=WAVE_BASE_URL=https://your-domain.example
```

## Если платформенные файлы нужно пересоздать

```bash
flutter create --platforms=android,windows .
```

## Важно

- Для Windows нужен установленный `Microsoft Edge WebView2 Runtime`.
- Если `flutter build windows` или `flutter run -d windows` ругается на plugin symlink, включите Windows Developer Mode.
