import React, { useEffect } from 'react'
import { useParams } from 'react-router-dom'

const ShortenUrlPage = () => {
    const { url } = useParams();

    useEffect(() => {
        if (url) {
            const backendBase = import.meta.env.VITE_BACKEND_URL || "";
            window.location.href = `${backendBase}/api/${url}`;
        }
    }, [url]);
  return <p>Redirecting...</p>;
}

export default ShortenUrlPage