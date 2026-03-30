package com.towpen.base.annotations.definitions;

import java.lang.annotation.*;

@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface TypeDetailConverter  {
	String fieldName() default "";
}
