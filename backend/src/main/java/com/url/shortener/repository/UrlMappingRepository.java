package com.url.shortener.repository;

import com.url.shortener.models.UrlMapping;
import com.url.shortener.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UrlMappingRepository
        extends JpaRepository<UrlMapping, Long> {

    UrlMapping findByShortUrl(String shortUrl);

    List<UrlMapping> findByUser(User user);

    Optional<UrlMapping> findByShortUrlAndUser(
            String shortUrl,
            User user
    );

    @Modifying
    @Query("""
        UPDATE UrlMapping u
        SET u.clickCount = u.clickCount + 1
        WHERE u.id = :id
    """)
    int incrementClickCount(@Param("id") Long id);
}