package com.towpen.utils.sort;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.text.RuleBasedCollator;
import java.util.*;

@SuppressWarnings("unchecked")
public class DtoComparator implements Comparator {

	final static Logger logger = LoggerFactory.getLogger(DtoComparator.class);
	// Init
	// --------------------------------------------------------------------------------------

	private List<String> getters;

	private boolean ascending;

	private RuleBasedCollator trr = null;

	private boolean strAsNumeric;



	public DtoComparator() {
		try {
			trr = new RuleBasedCollator("<a,A<b,B<c,C<ç,Ç<d,D<e,E<f,F<g,G<ğ,Ğ<h,H<ı,I<i,İ<j,J" + "<k,K<l,L<m,M<n,N<o,O<ö,Ö<p,P<r,R<s,S<ş,Ş<t,T<u,U<Ü,ü<v,V<y,Y<z,Z<'-'<' '<q,Q<w,W<x,X");
		} catch (ParseException e) {
			logger.error("{}", e.getMessage());
		}
	}

	public DtoComparator(String getter, boolean ascending) {
		this();
		this.getters = new ArrayList<String>();
		for (String name : getter.split("\\.")) {
			if (!name.startsWith("get")) {
				name = "get" + name.substring(0, 1).toUpperCase(Locale.ENGLISH) + name.substring(1);
			}
			this.getters.add(name);
		}
		this.ascending = ascending;
	}

	public DtoComparator(String getter) {
		this(getter, true);
	}

	public DtoComparator(String getter, boolean ascending, boolean strAsNumeric) {
		this();
		this.getters = new ArrayList<>();
		for (String name : getter.split("\\.")) {
			if (!name.startsWith("get")) {
				name = "get" + name.substring(0, 1).toUpperCase() + name.substring(1);
			}
			this.getters.add(name);
		}
		this.ascending = ascending;
		this.strAsNumeric = strAsNumeric;
	}


	public int compare(Object o1, Object o2) {
		try {
			Iterator<String> iter = getters.iterator();
			while (o1 != null && o2 != null && iter.hasNext()) {
				String getter = iter.next();
				o1 = o1.getClass().getMethod(getter, new Class[0]).invoke(o1, new Object[0]);
				o2 = o2.getClass().getMethod(getter, new Class[0]).invoke(o2, new Object[0]);
			}
		} catch (Exception e) {
			// If this exception occurs, then it is usually a fault of the DTO
			// developer.
			throw new RuntimeException("Cannot compare " + o1 + " with " + o2 + " on " + getters, e);
		}

		if (o1 == null) {
			return ascending ? -1 : 1; // If ascending, current null first.
		} else if (o2 == null) {
			return ascending ? 1 : -1; // If ascending, another null first.
		}

		if (strAsNumeric && o1 instanceof String && o2 instanceof String) {
			try {
				return (int) (Long.parseLong(o1.toString().replaceAll("\\D", "")) - Long.parseLong(o2.toString().replaceAll("\\D", "")));
			} catch (NumberFormatException nfe) {
				return 0;
			}
		} else if (o1 instanceof String && o2 instanceof String) {//
			if (ascending)
				return trr.compare(o1, o2);
			else
				return trr.compare(o2, o1);
		} else {
			if (ascending) {
				return ((Comparable) o1).compareTo(o2); // Ascending.
			} else {
				return ((Comparable) o2).compareTo(o1); // Descending.
			}
		}
	}

}
