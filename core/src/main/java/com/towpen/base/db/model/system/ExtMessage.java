package com.towpen.base.db.model.system;

import com.towpen.base.db.model.TOpenSimpleDbEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "ext_messages", uniqueConstraints = @UniqueConstraint(columnNames = "message_code"))
@Getter
@Setter
public class ExtMessage extends TOpenSimpleDbEntity {

    private static final long serialVersionUID = 1L;

    @Column(name = "message_code", nullable = false, length = 20)
    private String messageCode;

    @Column(name = "message_tr", nullable = false, length = 500)
    private String messageTr;

    @Column(name = "message_en", nullable = false, length = 500)
    private String messageEn;
}
