package com.towpen.base.db.model.system;

import com.towpen.base.db.model.TOpenSimpleDbEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "ext_bundles", uniqueConstraints = @UniqueConstraint(columnNames = "bundle_code"))
@Getter
@Setter
public class ExtBundle extends TOpenSimpleDbEntity {

    private static final long serialVersionUID = 1L;

    @Column(name = "bundle_code", nullable = false, length = 100)
    private String bundleCode;

    @Column(name = "bundle_message_tr", nullable = false, length = 500)
    private String bundleMessageTr;

    @Column(name = "bundle_message_en", nullable = false, length = 500)
    private String bundleMessageEn;
}
