package com.towpen.base.security.model;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

public class TOpenAuthenticationToken extends UsernamePasswordAuthenticationToken {


	private static final long serialVersionUID = 8355491026257721396L;
	private final String token;

	public TOpenAuthenticationToken(Object aPrincipal, Object aCredentials, Collection<? extends GrantedAuthority> anAuthorities, String token) {
		super(aPrincipal, aCredentials, anAuthorities);
		this.token = token;
	}
	public TOpenAuthenticationToken(Object aPrincipal, Object aCredentials, Collection<? extends GrantedAuthority> anAuthorities ) {
		this(aPrincipal, aCredentials, anAuthorities,null);
	}

	private transient TOpenSessionInstance sessionInstance;

	public TOpenSessionInstance getSessionInstance() {
		return sessionInstance;
	}

	public void setSessionInstance(TOpenSessionInstance sessionInstance) {
		setDetails(sessionInstance);
		this.sessionInstance = sessionInstance;
	}

	public String getToken() {
		return token;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = super.hashCode();
		result = prime * result + ((sessionInstance == null) ? 0 : sessionInstance.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!super.equals(obj))
			return false;
		if (getClass() != obj.getClass())
			return false;
		TOpenAuthenticationToken other = (TOpenAuthenticationToken) obj;
		if (sessionInstance == null) {
			if (other.sessionInstance != null)
				return false;
		} else if (!sessionInstance.equals(other.sessionInstance))
			return false;
		return true;
	}
}
