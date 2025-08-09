<?php

namespace Inovector\Mixpost\Support;

use GuzzleHttp\Exception\RequestException;
use GuzzleHttp\Promise\PromiseInterface;
use Illuminate\Http\Client\Response;
use Illuminate\Http\File as HttpFile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use RuntimeException;
use Exception;

class File
{
    public static function fromBase64(string $base64File, ?string $filename = null): UploadedFile
    {
        // Get file data base64 string
        $fileData = base64_decode(Arr::last(explode(',', $base64File)));

        return self::fromFileData($fileData, $filename);
    }

    public static function fromURL(string $url, ?string $filename = null): UploadedFile
    {
        if(filter_var($url, FILTER_VALIDATE_URL)){
            try {
                $response = self::fetchUrl($url);
            } catch (RequestException $e) {
                throw new RuntimeException($e->getMessage());
            } catch (Exception $e){
                throw new Exception($e->getMessage());
            }
            return self::fromFileData($response->body(), $filename);
        } else {
            throw new Exception('Failed to download file: URL is not valid');
        }
    }

    public static function fromFileData(string $fileData, ?string $filename = null): UploadedFile
    {
        // Create temp file and get its absolute path
        $tempFile = tmpfile();
        $tempFilePath = stream_get_meta_data($tempFile)['uri'];

        // Save file data in file
        file_put_contents($tempFilePath, $fileData);

        $tempFileObject = new HttpFile($tempFilePath);

        $file = new UploadedFile(
            $tempFileObject->getPathname(),
            $filename ?: $tempFileObject->getFilename(),
            $tempFileObject->getMimeType(),
            0,
            true // Mark it as test, since the file isn't from real HTTP POST.
        );

        // Close this file after response is sent.
        // Closing the file will cause to remove it from temp director!
        app()->terminating(function () use ($tempFile) {
            fclose($tempFile);
        });

        // return UploadedFile object
        return $file;
    }

    public static function fetchUrl(string $url, int $timeout = 10): PromiseInterface|Response
    {
        return Http::timeout($timeout)->get($url);
    }

    public static function getFilenameFromHttpResponse(Response $response, ?string $fallbackFilename = null): string
    {
        $contentDisposition = $response->header('Content-Disposition');

        if ($contentDisposition) {
            // Extract filename using regex
            if (preg_match('/filename="([^"]+)"/', $contentDisposition, $matches)) {
                return $matches[1];
            } elseif (preg_match('/filename\*=UTF-8\'\'([^;]+)/', $contentDisposition, $matches)) {
                return rawurldecode($matches[1]);
            }
        }

        // Try to get the file name from the URL
        $urlPath = parse_url($response->effectiveUri(), PHP_URL_PATH);

        if ($urlPath) {
            return basename($urlPath);
        }

        return $fallbackFilename ?: Str::random(40);
    }
}
