package com.google.api.client.http;

import com.google.api.client.auth.oauth2.Credential; 
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestInitializer;

import java.io.IOException;

public class RequestInitializerWrapper implements HttpRequestInitializer {	 
    
    private final Credential wrappedCredential; 

    public RequestInitializerWrapper(final Credential wrappedCredential) { 
        this.wrappedCredential = wrappedCredential; 
    }

    @Override 
    public final void initialize(final HttpRequest request) {
    	request.setConnectTimeout(0);
    	request.setReadTimeout(0);
    	request.setInterceptor(wrappedCredential);
    }

}