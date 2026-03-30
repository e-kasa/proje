package com.towpen.base.db.sequence;

public enum SequenceType {
	PARENT_SEQ("PARENT_SEQ"),

	AKS_ID_SEQ("AKS_ID_SEQ"),

	AUTHORIZATION_REASON_TASK_SEQ("AUTHORIZATION_REASON_TASK_SEQ"),

	IND_PROPOSAL_SEQ("IND_PROPOSAL_SEQ"),

	SMS_CONTENT_SEQ("SMS_CONTENT_SEQ"),

	EMAIL_TEMPLATE_SEQ("EMAIL_TEMPLATE_SEQ"),

	POLICY_SEQ("POLICY_SEQ"), BPM_INSTANCE_SEQ("BPM_INSTANCE_SEQ"), BPM_TASK_SEQ("BPM_TASK_SEQ"),

	KVKK_CONSENT_DATA_SEQ("KVKK_CONSENT_DATA_SEQ"),

	CALL_CREATE_POLICY_SERVICE_SEQ("CALL_CREATE_POLICY_SERVICE_SEQ"),

	ACCOUNTING_PROCESS_SEQ("ACCOUNTING_PROCESS_SEQ"),

	PAYMENT_RECEIVED_RECEIPT_SEQ("PAYMENT_RECEIVED_RECEIPT_SEQ"),

	PROPOSAL_RENEWAL_GROUP_SEQ("PROPOSAL_RENEWAL_GROUP_SEQ"),

	REASURANS_SEQ("REASURANS_SEQ"), GROUP_APP_SEQ("GROUP_APP_SEQ"),

	GROUP_PROPOSAL_LIST_SEQ("GROUP_PROPOSAL_LIST_SEQ"),

	PLAN_MAIN_COVER_CONCAT_SEQ("PLAN_MAIN_COVER_CONCAT_SEQ");

	private SequenceType(String sequenceName) {
		this.sequenceName = sequenceName;
		this.schemaName = null;
		this.isCurrentSchema = true;
	}

	private String schemaName;

	private boolean isCurrentSchema;

	private String sequenceName;

	public String getSchemaName() {
		return schemaName;
	}

	public String getSequenceName() {
		return sequenceName;
	}

	public boolean isCurrentSchema() {
		return isCurrentSchema;
	}

}
