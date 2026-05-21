namespace SudoKu.Exceptions;

/// <summary>
/// 数独异常基类，所有自定义异常的父类。
/// </summary>
public class SudokuException : Exception
{
    /// <summary>
    /// 初始化数独异常的新实例。
    /// </summary>
    public SudokuException()
    {
    }

    /// <summary>
    /// 使用指定的错误消息初始化数独异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    public SudokuException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// 使用指定的错误消息和内部异常初始化数独异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    /// <param name="innerException">导致当前异常的内部异常。</param>
    public SudokuException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

/// <summary>
/// 谜题生成异常，在谜题生成过程中发生错误时抛出。
/// </summary>
public class PuzzleGenerationException : SudokuException
{
    /// <summary>
    /// 初始化谜题生成异常的新实例。
    /// </summary>
    public PuzzleGenerationException()
    {
    }

    /// <summary>
    /// 使用指定的错误消息初始化谜题生成异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    public PuzzleGenerationException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// 使用指定的错误消息和内部异常初始化谜题生成异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    /// <param name="innerException">导致当前异常的内部异常。</param>
    public PuzzleGenerationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

/// <summary>
/// 验证错误类型枚举，定义谜题验证过程中可能出现的错误类型。
/// </summary>
public enum ValidationErrorType
{
    /// <summary>存在重复数字。</summary>
    DuplicateNumber,

    /// <summary>区域约束冲突。</summary>
    RegionConflict,

    /// <summary>行约束冲突。</summary>
    RowConflict,

    /// <summary>列约束冲突。</summary>
    ColumnConflict,

    /// <summary>无效的单元格值。</summary>
    InvalidCellValue,

    /// <summary>谜题无解。</summary>
    NoSolution,

    /// <summary>谜题存在多个解。</summary>
    MultipleSolutions,

    /// <summary>谜题不完整。</summary>
    Incomplete,

    /// <summary>杀手数独笼子约束冲突。</summary>
    CageConstraintViolation,

    /// <summary>未知验证错误。</summary>
    Unknown
}

/// <summary>
/// 谜题验证异常，在谜题验证过程中发现错误时抛出。
/// </summary>
public class PuzzleValidationException : SudokuException
{
    /// <summary>
    /// 初始化谜题验证异常的新实例。
    /// </summary>
    public PuzzleValidationException()
    {
    }

    /// <summary>
    /// 使用指定的错误消息初始化谜题验证异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    public PuzzleValidationException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// 使用指定的错误消息和验证错误类型初始化谜题验证异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    /// <param name="errorType">验证错误类型。</param>
    public PuzzleValidationException(string message, ValidationErrorType errorType)
        : base(message)
    {
        ErrorType = errorType;
    }

    /// <summary>
    /// 使用指定的错误消息、验证错误类型和内部异常初始化谜题验证异常的新实例。
    /// </summary>
    /// <param name="message">描述错误的字符串。</param>
    /// <param name="errorType">验证错误类型。</param>
    /// <param name="innerException">导致当前异常的内部异常。</param>
    public PuzzleValidationException(string message, ValidationErrorType errorType, Exception innerException)
        : base(message, innerException)
    {
        ErrorType = errorType;
    }

    /// <summary>获取验证错误类型。</summary>
    public ValidationErrorType ErrorType { get; }
}

/// <summary>
/// 游戏生成取消异常，当用户取消游戏生成时抛出。
/// </summary>
public class GameGenerationCancelledException : SudokuException
{
    public GameGenerationCancelledException() { }
    public GameGenerationCancelledException(string message) : base(message) { }
    public GameGenerationCancelledException(string message, Exception innerException) : base(message, innerException) { }
}

/// <summary>
/// 游戏生成超时异常，当游戏生成超过指定时间时抛出。
/// </summary>
public class GameGenerationTimeoutException : SudokuException
{
    public GameGenerationTimeoutException() { }
    public GameGenerationTimeoutException(string message) : base(message) { }
    public GameGenerationTimeoutException(string message, Exception innerException) : base(message, innerException) { }
}

/// <summary>
/// 游戏生成无解异常，当游戏生成无法找到解时抛出。
/// </summary>
public class GameGenerationNoSolutionException : SudokuException
{
    public GameGenerationNoSolutionException() { }
    public GameGenerationNoSolutionException(string message) : base(message) { }
    public GameGenerationNoSolutionException(string message, Exception innerException) : base(message, innerException) { }
}

/// <summary>
/// 游戏逻辑异常，当游戏逻辑发生错误时抛出。
/// </summary>
public class GameLogicException : SudokuException
{
    public GameLogicException() { }
    public GameLogicException(string message) : base(message) { }
    public GameLogicException(string message, Exception innerException) : base(message, innerException) { }
}

/// <summary>
/// 游戏验证异常，当游戏数据验证失败时抛出。
/// </summary>
public class GameValidationException : SudokuException
{
    public GameValidationException() { }
    public GameValidationException(string message) : base(message) { }
    public GameValidationException(string message, Exception innerException) : base(message, innerException) { }
}

/// <summary>
/// 游戏存储异常，当游戏数据存储或读取失败时抛出。
/// </summary>
public class GameStorageException : SudokuException
{
    public GameStorageException() { }
    public GameStorageException(string message) : base(message) { }
    public GameStorageException(string message, Exception innerException) : base(message, innerException) { }
}
