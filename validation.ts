import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email("Informe um e-mail válido"),
  password: z.string().min(1, "Informe sua senha"),
});

export const emailSchema = z.object({
  email: z.string().trim().toLowerCase().email("Informe um e-mail válido"),
});

export const newPasswordSchema = z
  .object({
    password: z.string().min(8, "A senha deve ter ao menos 8 caracteres"),
    confirm: z.string(),
  })
  .refine((v) => v.password === v.confirm, { message: "As senhas não coincidem", path: ["confirm"] });
