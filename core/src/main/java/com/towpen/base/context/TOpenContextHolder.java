package com.towpen.base.context;

public class TOpenContextHolder {
	private static final ThreadLocal<TOpenContext> CONTEXT = new InheritableThreadLocal<>();

	public static TOpenContext getContext() {
		return CONTEXT.get();
	}

	public static void setContext(TOpenContext topenContext) {
		CONTEXT.set(topenContext);
	}
}
