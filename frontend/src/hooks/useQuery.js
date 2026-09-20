import { useQuery } from "react-query";
import dayjs from "dayjs";
import api from "../api/api";


export const useFetchMyShortUrls = (token, onError) => {
    return useQuery(
        "my-shortenurls",
        async () => {
            return await api.get(
                "/api/urls/myurls",
                {
                    headers: {
                        "Content-Type": "application/json",
                        Accept: "application/json",
                        Authorization: "Bearer " + token,
                    },
                }
            );
        },
        {
            select: (data) => {
                const sortedData = data.data.sort(
                    (a, b) => new Date(b.createdDate) - new Date(a.createdDate)
                );

                return sortedData;
            },
            onError,
            staleTime: 5000
        }
    );
};


export const useFetchTotalClicks = (token, onError) => {
    return useQuery(
        "url-totalclick",
        async () => {
            const endDate = dayjs();
            const startDate = endDate.subtract(1, "year");

            return await api.get(
                `/api/urls/totalClicks?startDate=${startDate.format("YYYY-MM-DD")}&endDate=${endDate.format("YYYY-MM-DD")}`,
                {
                    headers: {
                        "Content-Type": "application/json",
                        Accept: "application/json",
                        Authorization: "Bearer " + token,
                    },
                }
            );
        },
        {
            select: (data) => {
                const convertToArray = Object.keys(data.data).map((key) => ({
                    clickDate: key,
                    count: data.data[key],
                }));

                return convertToArray;
            },
            onError,
            staleTime: 5000
        }
    );
};