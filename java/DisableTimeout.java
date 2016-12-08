package com.google.api.client.http;

import java.io.IOException;

  public class DisableTimeout implements HttpRequestInitializer {
    public void initialize(HttpRequest request) {
      request.setConnectTimeout(0);
      request.setReadTimeout(0);
    }
  }
