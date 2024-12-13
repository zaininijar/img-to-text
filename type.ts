export interface Questions {
    category: string;
    question: string;
    picture: string | null;
    options: { [key: string]: boolean };
}
