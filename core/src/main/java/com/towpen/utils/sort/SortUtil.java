package com.towpen.utils.sort;

import lombok.experimental.UtilityClass;

import java.util.Collections;
import java.util.List;

@UtilityClass
public class SortUtil {
	@SuppressWarnings("unchecked")
	public static <T> void sortThis(List<T> list, String columnName, boolean asc)   {
		Collections.sort(list, new DtoComparator(columnName, asc));
	}

	@SuppressWarnings("unchecked")
	public static <T> void sortThisStringNumerical(List<T> list, String columnName, boolean asc, boolean strAsNum)   {
		Collections.sort(list, new DtoComparator(columnName, asc, strAsNum));
	}
}
