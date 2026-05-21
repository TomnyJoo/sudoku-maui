using SudoKu.Helpers;
using SudoKu.Exceptions;

namespace SudoKu.Services;

public class ErrorHandler : IErrorHandler
{
    public static readonly ErrorHandler Instance = new();

    private ErrorHandler() { }

    public string HandleException(Exception exception)
    {
        return exception switch
        {
            PuzzleGenerationException e => $"游戏生成失败: {e.Message}",
            GameGenerationCancelledException e => $"游戏生成已取消: {e.Message}",
            GameGenerationTimeoutException e => $"游戏生成超时: {e.Message}",
            GameGenerationNoSolutionException e => $"游戏生成无解: {e.Message}",
            GameLogicException e => $"游戏逻辑错误: {e.Message}",
            GameValidationException e => $"游戏验证错误: {e.Message}",
            GameStorageException e => $"游戏存储错误: {e.Message}",
            SudokuException e => e.Message,
            _ => $"发生未知错误: {exception?.Message ?? "未知错误"}"
        };
    }

    public void LogError(Exception exception, string? context = null)
    {
        var message = context != null ? $"[{context}] {exception}" : exception.ToString();
        AppLogger.Error(message, exception);
    }

    public void LogError(Exception exception, string? context, Exception innerException)
    {
        var message = context != null ? $"[{context}] {exception}" : exception.ToString();
        AppLogger.Error(message, innerException);
    }

    public bool IsGameLogicError(Exception exception) =>
        exception is GameLogicException || exception is GameValidationException;

    public bool IsGameStorageError(Exception exception) =>
        exception is GameStorageException;

    public bool IsGameGenerationError(Exception exception) =>
        exception is PuzzleGenerationException ||
        exception is GameGenerationCancelledException ||
        exception is GameGenerationTimeoutException ||
        exception is GameGenerationNoSolutionException;
}
