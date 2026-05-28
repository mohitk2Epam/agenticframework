import { LightningElement, api } from 'lwc';

export default class SimpleGreeting extends LightningElement {
    @api userName;

    get greeting() {
        return this.userName ? `Hello, ${this.userName}!` : 'Hello, World!';
    }
}
