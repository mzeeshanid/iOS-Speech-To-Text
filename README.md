#iOS-Speech-To-Text
==================

This library uses the Google Voice API and the Speex audio codec for speech-to-text on iOS 

This project was forked from: https://github.com/mzeeshanid

==================

#Usage
==================
- Create an instance of `SpeechTranscriber`
- Set delegate and optional data points delegate
- Call `startRecording` and `stopRecording`

```
    self.transcriber = [SpeechTranscriber new];
    self.transcriber.delegate = self;
    self.transcriber.dataPointsDelegate = self;
    
    (...)
    
    -(BOOL)speechTranscriberDidReceiveVoiceResponse:(NSData *)data {
      NSError *jsonError;
      NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments     error:&jsonError];
      NSString *transcribedText = [response[@"hypotheses"] firstObject][@"utterance"];
    return response != nil;
}

```
