package com.url.shortener.service;

import com.url.shortener.dtos.ClickEventDTO;
import com.url.shortener.dtos.UrlMappingDTO;
import com.url.shortener.models.ClickEvent;
import com.url.shortener.models.UrlMapping;
import com.url.shortener.models.User;
import com.url.shortener.repository.ClickEventRepository;
import com.url.shortener.repository.DailyClickStatsProjection;
import com.url.shortener.repository.UrlMappingRepository;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class UrlMappingService {

    private UrlMappingRepository urlMappingRepository;
    private ClickEventRepository clickEventRepository;

    public UrlMappingDTO createShortUrl(String originalUrl, User user) {

    for (int attempt = 0; attempt < 5; attempt++) {
        try {
            String shortUrl = generateShortUrl();

            UrlMapping urlMapping = new UrlMapping();
            urlMapping.setOriginalUrl(originalUrl);
            urlMapping.setShortUrl(shortUrl);
            urlMapping.setUser(user);
            urlMapping.setCreatedDate(LocalDateTime.now());

            UrlMapping savedUrlMapping =
                    urlMappingRepository.saveAndFlush(urlMapping);

            return convertToDto(savedUrlMapping);

        } catch (DataIntegrityViolationException e) {
            if (attempt == 4) {
                throw e;
            }
        }
    }

    throw new IllegalStateException("Could not generate a unique short URL");
}
    private UrlMappingDTO convertToDto(UrlMapping urlMapping){
        UrlMappingDTO urlMappingDTO = new UrlMappingDTO();
        urlMappingDTO.setId(urlMapping.getId());
        urlMappingDTO.setOriginalUrl(urlMapping.getOriginalUrl());
        urlMappingDTO.setShortUrl(urlMapping.getShortUrl());
        urlMappingDTO.setClickCount(urlMapping.getClickCount());
        urlMappingDTO.setCreatedDate(urlMapping.getCreatedDate());
        urlMappingDTO.setUsername(urlMapping.getUser().getUsername());
        return urlMappingDTO;
    }

    private String generateShortUrl() {
        String characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

        Random random = new Random();
        StringBuilder shortUrl = new StringBuilder(8);

        for (int i = 0; i < 8; i++) {
            shortUrl.append(characters.charAt(random.nextInt(characters.length())));
        }
        return shortUrl.toString();
    }

    public List<UrlMappingDTO> getUrlsByUser(User user) {
        return urlMappingRepository.findByUser(user).stream()
                .map(this::convertToDto)
                .toList();
    }

    public List<ClickEventDTO> getClickEventsByDate(
        String shortUrl,
        LocalDateTime start,
        LocalDateTime end,
        User user) {

       UrlMapping urlMapping =
            urlMappingRepository
                    .findByShortUrlAndUser(shortUrl, user)
                    .orElse(null);

        if (urlMapping == null) {
        return List.of();
        }

        return clickEventRepository
            .getDailyClicksForUrl(
                    urlMapping.getId(),
                    start,
                    end
            )
            .stream()
            .map(row -> {
                ClickEventDTO dto = new ClickEventDTO();
                dto.setClickDate(row.getClickDate());
                dto.setCount(row.getCount());
                return dto;
            })
            .toList();
     }

      public Map<LocalDate, Long> getTotalClicksByUserAndDate(
        User user,
        LocalDate start,
        LocalDate end) {

        return clickEventRepository
            .getDailyClicksForUser(
                    user.getId(),
                    start.atStartOfDay(),
                    end.plusDays(1).atStartOfDay()
            )
            .stream()
            .collect(Collectors.toMap(
                    DailyClickStatsProjection::getClickDate,
                    DailyClickStatsProjection::getCount
            ));
      }

    @Transactional
    public UrlMapping getOriginalUrl(String shortUrl) {

        UrlMapping urlMapping =
            urlMappingRepository.findByShortUrl(shortUrl);

        if (urlMapping == null) {
        return null;
        }

        urlMappingRepository.incrementClickCount(
            urlMapping.getId()
        );

        ClickEvent clickEvent = new ClickEvent();
        clickEvent.setClickDate(LocalDateTime.now());
        clickEvent.setUrlMapping(urlMapping);

        clickEventRepository.save(clickEvent);

        return urlMapping;
     }
   }
