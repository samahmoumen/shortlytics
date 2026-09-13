package com.url.shortener.repository;

import com.url.shortener.models.ClickEvent;
import com.url.shortener.models.UrlMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ClickEventRepository
        extends JpaRepository<ClickEvent, Long> {

    @Query(value = """
        SELECT
            CAST(ce.click_date AS DATE) AS clickDate,
            COUNT(*) AS count
        FROM click_event ce
        WHERE ce.url_mapping_id = :urlMappingId
          AND ce.click_date >= :start
          AND ce.click_date < :end
        GROUP BY CAST(ce.click_date AS DATE)
        ORDER BY CAST(ce.click_date AS DATE)
        """,
        nativeQuery = true)
    List<DailyClickStatsProjection> getDailyClicksForUrl(
            @Param("urlMappingId") Long urlMappingId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );

    @Query(value = """
        SELECT
            CAST(ce.click_date AS DATE) AS clickDate,
            COUNT(*) AS count
        FROM click_event ce
        JOIN url_mapping um
            ON ce.url_mapping_id = um.id
        WHERE um.user_id = :userId
          AND ce.click_date >= :start
          AND ce.click_date < :end
        GROUP BY CAST(ce.click_date AS DATE)
        ORDER BY CAST(ce.click_date AS DATE)
        """,
        nativeQuery = true)
    List<DailyClickStatsProjection> getDailyClicksForUser(
            @Param("userId") Long userId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );
}