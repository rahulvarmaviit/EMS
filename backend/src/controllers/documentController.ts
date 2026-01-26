import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const uploadDocument = async (req: Request, res: Response) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const { title } = req.body;
        if (!title) {
            return res.status(400).json({ error: 'Title is required' });
        }

        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        const existingDoc = await prisma.document.findFirst({
            where: {
                user_id: userId,
                title: title
            }
        });

        if (existingDoc) {
            // Update existing document
            const document = await prisma.document.update({
                where: { id: existingDoc.id },
                data: {
                    file_path: req.file.path,
                    uploaded_at: new Date()
                }
            });
            return res.status(200).json({ message: 'Document updated successfully', document });
        } else {
            // Create new
            const document = await prisma.document.create({
                data: {
                    title,
                    file_path: req.file.path,
                    user_id: userId,
                },
            });
            return res.status(201).json({ message: 'Document uploaded successfully', document });
        }

    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: 'Failed to upload document' });
    }
};

export const getDocuments = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        const documents = await prisma.document.findMany({
            where: {
                user_id: userId,
            },
            orderBy: {
                uploaded_at: 'desc',
            },
        });

        res.json(documents);
    } catch (error) {
        console.error('Get documents error:', error);
        res.status(500).json({ error: 'Failed to fetch documents' });
    }
};
