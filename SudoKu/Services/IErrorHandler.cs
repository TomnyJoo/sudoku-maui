namespace SudoKu.Services;

public interface IErrorHandler
{
    string HandleException(Exception exception);
    void LogError(Exception exception, string? context = null);
    void LogError(Exception exception, string? context, Exception innerException);
    bool IsGameLogicError(Exception exception);
    bool IsGameStorageError(Exception exception);
    bool IsGameGenerationError(Exception exception);
}
