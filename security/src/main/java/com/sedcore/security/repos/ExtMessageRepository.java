package com.sedcore.security.repos;

import com.towpen.base.db.model.system.ExtMessage;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExtMessageRepository extends BaseDaoRepository<ExtMessage> {
    @Query(value = "SELECT * FROM ext_messages", nativeQuery = true)
    List<ExtMessage> findAllMessages();
}
