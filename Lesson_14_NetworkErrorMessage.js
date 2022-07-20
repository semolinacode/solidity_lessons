export function NetworkErrorMessage({message, dismis}) {
    return (
        <div>
            {message}
            <button type="button" onClick={dismis}>
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
    )
}